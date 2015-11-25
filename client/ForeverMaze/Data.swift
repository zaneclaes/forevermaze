//
//  Data.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/24/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import PromiseKit
import Firebase

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
  /**
   * Object IDs will be loaded and stored into GameObject cache
   * (not returned via the promise)
   */
  static func loadObjects(ids: [String]) -> Promise<Void> {
    var promises = Array<Promise<Void>>()
    for id in ids {
      if GameObject.cache[id] != nil {
        continue
      }
      let promise = loadObject(id).then { gameObject in
        return Promise { fulfill, reject in fulfill() }
      }
      promises.append(promise)
    }
    return when(promises)
  }
  /**
   * Uses loadSnapshot to infer and create a GameObject
   * In GameObject land, an ID is a path
   * Therefore, we can separate on the `/` character and infer
   * the type of class to use to instantiate the object.
   */
  static func loadObject(id: String!) -> Promise<GameObject!> {
    return loadSnapshot(id).then { (snapshot) -> Promise<GameObject!> in
      return GameObject.factory(snapshot)
    }
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
