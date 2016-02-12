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

extension FDataSnapshot {
  public func configValue(childPath: String) -> AnyObject? {
    guard self.hasChild(childPath) else {
      return nil
    }
    let experimentPath = "\(childPath)Experiment"
    let exp = self.hasChild(experimentPath) ? self.childSnapshotForPath(experimentPath).value : nil
    let val = self.childSnapshotForPath(childPath).value
    if exp is NSDictionary {
      let experiment = exp as! NSDictionary
      let treatment = Analytics.getTreatment(experimentPath, treatments: experiment.allKeys as! [String])
      let expVal = self.childSnapshotForPath(experimentPath).childSnapshotForPath(treatment).value
      return expVal is NSNull ? nil : expVal
    }
    if val is NSNull {
      return nil
    }
    return val
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
    guard firebasePath != nil else {
      fulfill(nil)
      return promise
    }
    let connection = Firebase(url: Config.firebaseUrl + firebasePath)
    connection.observeSingleEventOfType(.Value, withBlock: { snapshot in
      if !promise.resolved {
        let ret = snapshot.value is NSNull ? nil : snapshot
        fulfill(ret)
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
