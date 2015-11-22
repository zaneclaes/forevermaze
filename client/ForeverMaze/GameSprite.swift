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

  private let attributes:Array<String>

  init (snapshot: FDataSnapshot!, attributes: Array<String>) {
    self.connection = snapshot.ref
    self.snapshot = snapshot
    self.attributes = attributes
    self.observing = true
    super.init()
    beginObserving()
  }

  func beginObserving() {
    for attribute in self.attributes {
      self.addObserver(self, forKeyPath: attribute, options: [.New, .Old], context: &KVOContext)
    }
  }

  func endObserving() {
    for attribute in self.attributes {
      self.removeObserver(self, forKeyPath: attribute)
    }
  }

  // Toggle the observers for the attributes
  var observing: Bool {
    didSet {
      self.observing ? self.beginObserving() : self.endObserving()
    }
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

  deinit {
    self.observing = false
    self.connection.removeAllObservers()
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
