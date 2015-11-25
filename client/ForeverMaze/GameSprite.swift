//
//  GameSprite.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import Firebase
import PromiseKit

private var KVOContext = 0

class GameSprite : NSObject {
  let connection: Firebase!
  let snapshot: FDataSnapshot!

  var sprite = SKSpriteNode()

  private var properties:Array<String>

  init (snapshot: FDataSnapshot!) {
    self.connection = snapshot.ref
    self.snapshot = snapshot
    self.properties = []
    super.init()

    for property in self.firebaseProperties {
      // Assign the initial variable from the snapshot:
      if snapshot.hasChild(property) {
        let val = snapshot.childSnapshotForPath(property).value
        self.setValue(val, forKey: property)
      }

      // Begin KVO:
      self.addProperty(property)
    }
  }

  var firebaseProperties:[String] {
    return Utils.getProperties(self, filter: { (name, attributes) -> (Bool) in
      // Not read-only implies writablitiy, or Q implies private (I think?)
      return attributes.rangeOfString(",R") != nil && attributes.rangeOfString("Q,") == nil
    })
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
}
