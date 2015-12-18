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
        DDLogWarn("[TIMEOUT] [FIREBASE-WRITE] \(self) -> \(value)")
        reject(Errors.network)
      }
    }

    return promise
  }
}

class Data {
  
  static var promiseObjects:[String:Promise<GameObject!>] = [:]
  /**
   * Uses loadSnapshot to infer and create a GameObject
   * In GameObject land, an ID is a path
   * Therefore, we can separate on the `/` character and infer
   * the type of class to use to instantiate the object.
   */
  static func loadObject(id: String!) -> Promise<GameObject!> {
    guard self.promiseObjects[id] != nil else {
      DDLogDebug("Loading Object \(id)")

      let promise:Promise<GameObject!> = firstly {
        return loadSnapshot(id)
      }.then { snapshot -> Promise<GameObject!> in
        return GameObject.factory(id, snapshot: snapshot)
      }.always { () -> Void in
        promiseObjects.removeValueForKey(id)
      }
      self.promiseObjects[id] = promise
      return promise
    }
    
    return self.promiseObjects[id]!
  }
  /**
   * Given a path to a firebase object, get the snapshot with a timeout.
   */
  static func loadSnapshot(firebasePath: String!) -> Promise<FDataSnapshot?> {
    let (promise, fulfill, _) = Promise<FDataSnapshot?>.pendingPromise()
    let connection = Firebase(url: Config.firebaseUrl + firebasePath)
    connection.observeSingleEventOfType(.Value, withBlock: { snapshot in
      if !promise.resolved {
        fulfill(snapshot)
      }
    })
    after(Config.timeout).then { () -> Void in
      if !promise.resolved {
        DDLogWarn("[TIMEOUT] [FIREBASE-READ] \(firebasePath)")
        fulfill(nil)
        //reject(Errors.network)
      }
    }
    return promise
  }
}
