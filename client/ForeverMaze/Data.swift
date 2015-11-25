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
