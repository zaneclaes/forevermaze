//
//  GameSprite.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase
import PromiseKit

private var KVOContext = 0

class GameSprite : NSObject {
  let connection: Firebase!
  let snapshot: FDataSnapshot!

  private var properties:Array<String>

  init (snapshot: FDataSnapshot!) {
    self.connection = snapshot.ref
    self.snapshot = snapshot
    self.properties = []
    super.init()

    for attribute in self.getDynamicAttributes() {
      self.addProperty(attribute)
    }
  }

  func getDynamicAttributes() -> [String] {
    return Utils.getWritableProperties(self)
  }

  func addProperty(property: String!) {
    guard !properties.contains(property) else {
      return
    }
    properties.append(property)
    self.addObserver(self, forKeyPath: property, options: [.New, .Old], context: &KVOContext)
  }

  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if let property = keyPath,
      newValue = change![NSKeyValueChangeNewKey],
      oldValue = change![NSKeyValueChangeOldKey] {
        if !newValue.isEqual(oldValue) {
          self.connection.childByAppendingPath(property).setValue(newValue)
        }
    }
  }

  func cleanup() {
    for property in self.properties {
      self.removeObserver(self, forKeyPath: property)
    }
    self.connection.removeAllObservers()
  }

  deinit {
    cleanup()
  }

  static func loadFromPath(relativePath: String!) -> Promise<FDataSnapshot> {
    return Promise { fulfill, reject in
      // TODO: Timeouts?? Connection errors?

      let connection = Firebase(url: Config.firebaseUrl + relativePath)
      connection.observeEventType(.Value, withBlock: { snapshot in
        connection.removeAllObservers()
        fulfill(snapshot)
      })
    }
  }
}
