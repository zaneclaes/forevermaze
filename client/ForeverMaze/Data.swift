//
//  Data.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/24/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import PromiseKit
import Firebase
import CocoaLumberjack

extension Firebase {
  public func write(value: AnyObject!) -> Promise<Void> {
    return Promise { fulfill, reject in
      after(life: Config.timeout).then {
        reject(Errors.network)
      }

      self.setValue(value, withCompletionBlock: { (error, firebase) -> Void in
        if error == nil {
          fulfill()
        }
        else {
          reject(error)
        }
      })
    }
  }
}

class Data {
  
  static var promiseObjects:[String:Promise<Void>] = [:]
  /**
   * Object IDs will be loaded and stored into GameObject cache
   * (not returned via the promise)
   */
  static func loadObjects(ids: [String]) -> Promise<Void> {
    var promises = Array<Promise<Void>>()
    for id in Set(ids) {
      if GameObject.cache[id] == nil {
        promises.append(loadObject(id))
      }
    }
    return promises.count > 0 ? when(promises) : Promise<Void>()
  }
  /**
   * Uses loadSnapshot to infer and create a GameObject
   * In GameObject land, an ID is a path
   * Therefore, we can separate on the `/` character and infer
   * the type of class to use to instantiate the object.
   */
  static func loadObject(id: String!) -> Promise<Void> {
    if self.promiseObjects[id] == nil {
      DDLogDebug("Loading Object \(id)")
      
      self.promiseObjects[id] = firstly {
        return loadSnapshot(id)
      }.then { snapshot in
        return GameObject.factory(id, snapshot: snapshot)
      }.then { (gameObject) -> Void in
        DDLogDebug("Loaded object: \(gameObject)")
        promiseObjects.removeValueForKey(id)
      }
    }
    
    return self.promiseObjects[id]!
  }
  /**
   * Given a path to a firebase object, get the snapshot with a timeout.
   */
  static func loadSnapshot(firebasePath: String!) -> Promise<FDataSnapshot> {
    return Promise { fulfill, reject in
      after(life: Config.timeout).then {
        reject(Errors.network)
      }

      let connection = Firebase(url: Config.firebaseUrl + firebasePath)
      connection.observeEventType(.Value, withBlock: { snapshot in
        connection.removeAllObservers()
        fulfill(snapshot)
      })
    }
  }
}
