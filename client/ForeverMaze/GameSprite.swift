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
import CocoaLumberjack

private var KVOContext = 0

class GameSprite : NSObject {
  let connection: Firebase!
  var snapshot: FDataSnapshot!
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

    //
    // When we detect that a value is changed remotely, check if it differs from the
    // local value. If so, trigger a method so subclasses can respond to the value change.
    //
    self.connection.observeEventType(.Value, withBlock: { snapshot in
      for property in self.firebaseProperties {
        // Assign the initial variable from the snapshot:
        self.snapshot = snapshot
        let oldValue = self.valueForKey(property)!
        if snapshot.hasChild(property) {
          let newValue = snapshot.childSnapshotForPath(property).value!
          if !newValue.isEqual(oldValue) {
            DDLogDebug("\(self) [Remote Value Changed]: \(property) \(oldValue) -> \(newValue)")
            self.setValue(newValue, forKey: property)
            self.onPropertyChangedRemotely(property, oldValue: oldValue)
          }
        }
        else if self.removeValue(property) {
          self.onPropertyChangedRemotely(property, oldValue: oldValue)
        }
      }
    })
  }

  var gameScene:GameScene? {
    return self.sprite.scene as? GameScene
  }

  // This is a dangerous scenario. The server does not have a representation of this object. We're setting it to nil locally.
  // However, some values may not be nil, and this could cause a crash. Or, if the key is an array, we may want to simply empty
  // it out rather than nilling it.
  func removeValue(property: String) -> Bool {
    let val = self.valueForKey(property)
    guard val != nil && !self.guardedProperties.contains(property) else {
      return false
    }
    let type = "\(self.valueForKey(property)!.dynamicType)"
    var newValue:AnyObject? = nil
    if type.rangeOfString("NSArray") != nil {
      newValue = []
    }
    else if type.rangeOfString("Number") != nil {
      newValue = 0
    }
    else if type.rangeOfString("Bool") != nil {
      newValue = false
    }
    if newValue == nil || !val!.isEqual(newValue) {
      self.setValue(newValue, forKey: property)
      return true
    }
    else {
      return false
    }
  }

  // Called when a remote change for a property is detected. Should be overwritten by children.
  func onPropertyChangedRemotely(property: String, oldValue: AnyObject) {

  }

  // Properties which are not observed
  var localProperties:[String] {
    return ["snapshot","sprite"]
  }

  // Properties which may not be nilled
  var guardedProperties:[String] {
    return []
  }

  var firebaseProperties:[String] {
    return getProperties(self, filter: { (name, attributes) -> (Bool) in
      if self.localProperties.contains(name) {
        return true
      }
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
          var remoteChanged = true
          if self.snapshot.hasChild(property) {
            let remoteValue = self.snapshot.childSnapshotForPath(property).value!
            remoteChanged = !newValue.isEqual(remoteValue)
          }
          if remoteChanged {
            DDLogDebug("\(self) writing value \(property) from \(oldValue) to \(newValue) to Firebase")
            self.connection.childByAppendingPath(property).setValue(newValue)
          }
        }
    }
  }

  func cleanup() {
    for property in self.properties {
      self.removeObserver(self, forKeyPath: property)
    }
    self.properties.removeAll()
    self.connection.removeAllObservers()
    self.sprite.removeFromParent()
  }

  deinit {
    cleanup()
    DDLogDebug("[DEALLOC] \(self)")
  }
}
