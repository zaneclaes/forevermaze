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
    let (promise, fulfill, reject) = Promise<Void>.pendingPromise()

    self.setValue(value, withCompletionBlock: { (error, firebase) -> Void in
      if !promise.resolved {
        if error == nil {
          fulfill()
        }
        else {
          reject(error)
        }
      }
    })

    after(Config.timeout).then { () -> Void in
      if !promise.resolved {
        reject(Errors.network)
      }
    }

    return promise
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
    guard self.promiseObjects[id] != nil else {
      DDLogDebug("Loading Object \(id)")

      let promise:Promise<Void> = firstly {
        return loadSnapshot(id)
      }.then { snapshot -> Promise<GameObject!> in
        return GameObject.factory(id, snapshot: snapshot)
      }.then { (gameObject) -> Void in
        DDLogDebug("Loaded object: \(id) -> \(gameObject)")
      }.always { () -> Void in
        promiseObjects.removeValueForKey(id)
      }.recover { (error) -> Void in
        DDLogError("Failed to load \(id)...")
      }
      self.promiseObjects[id] = promise
      return promise
    }
    
    return self.promiseObjects[id]!
  }
  /**
   * Given a path to a firebase object, get the snapshot with a timeout.
   */
  static func loadSnapshot(firebasePath: String!) -> Promise<FDataSnapshot> {
    let (promise, fulfill, reject) = Promise<FDataSnapshot>.pendingPromise()
    let connection = Firebase(url: Config.firebaseUrl + firebasePath)
    connection.observeEventType(.Value, withBlock: { snapshot in
      if !promise.resolved {
        connection.removeAllObservers()
        fulfill(snapshot)
      }
    })
    after(Config.timeout).then { () -> Void in
      if !promise.resolved {
        connection.removeAllObservers()
        reject(Errors.network)
      }
    }
    return promise
  }
}
