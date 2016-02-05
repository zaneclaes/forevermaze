//
//  WorldObject.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import Firebase
import PromiseKit
import CocoaLumberjack

class GameObject : GameStatic {
  private dynamic var x: UInt = 0
  private dynamic var y: UInt = 0
  private var currentAnimationKey = ""

  /**
   * Write all the missing SKTextures into the textureCache 
   * Also preload them from disk to avoid any later flickering
   */
  func draw() -> Promise<GameObject!> {
    return Animation.preload(assetName).then { (animation) -> Promise<GameObject!> in
      self.currentAnimationKey = ""
      self.sprite = self.animation!.createSprite(.Idle, direction: .S)
      self.assignScale()
      self.updateAnimation()
      return Promise<GameObject!>(self)
    }
  }
  
  var assetName:String {
    return "hero"
  }
  
  var speed:Double {
    return 1
  }
  
  var animation:Animation? {
    return Animation.cache[assetName]
  }

  func updateAnimation(group: AnimationGroup) {
    guard self.animation != nil else {
      return
    }
    let key = animation!.getKey(group, direction: direction)
    if key != currentAnimationKey {
      currentAnimationKey = key
      self.sprite.removeActionForKey(Animation.actionKey)
      self.sprite.runAction(self.animation!.getAction(group, direction: direction, speed: self.speed), withKey: Animation.actionKey)
    }
    self.sprite.xScale = isReversedAnimation ? -Config.objectScale : Config.objectScale
  }
  
  func updateAnimation() {
    guard self.gameScene != nil else {
      self.updateAnimation(.Idle)
      return
    }
    let mobile = self as? Mobile
    let group:AnimationGroup = mobile != nil && self.gameScene!.isObjectMoving(mobile!) ? .Walking : .Idle
    self.updateAnimation(group)
  }
  
  private var isReversedAnimation:Bool {
    return self.direction == .E || self.direction == .W
  }

  // `dir` is backed by Firebase, the primitive type which supports direction
  private dynamic var dir:Int = 0 {
    didSet {
      if oldValue != self.dir {
        self.updateAnimation()
      }
    }
  }

  var direction:Direction {
    set {
      if self.dir != newValue.rawValue {
        self.dir = newValue.rawValue
        self.updateAnimation()
      }
    }
    get {
      return Direction(rawValue: clamp(self.dir, lower: 0, upper: Direction.directions.count - 1))!
    }
  }

  var size: MapSize {
    return MapSize(width: 1, height: 1)
  }

  var coordinate: Coordinate {
    set {
      self.gameScene?.tiles[self.coordinate.description]?.removeObject(self)
      self.x = newValue.x
      self.y = newValue.y
      self.gameScene?.tiles[self.coordinate.description]?.addObject(self)
    }
    get {
      return Coordinate(x: self.x, y: self.y)
    }
  }

  var id: String {
    guard self.connection != nil else {
      return "<\(self.dynamicType)>"
    }
    return self.connection.description
      .stringByReplacingOccurrencesOfString(Config.firebaseUrl, withString: "")
  }

  var isOnScreen:Bool {
    guard gameScene != nil else {
      return false
    }
    return gameScene!.isCoordinateOnScreen(coordinate, includeBuffer: false)
  }

  /**
   * Given a data snapshot, inspect path components to infer and build an object
   */
  static func factory(objId: String, snapshot: FDataSnapshot?) -> Promise<GameObject!> {
    guard snapshot != nil else {
      return Promise<GameObject!>(nil)
    }

    let path = snapshot!.ref.description.stringByReplacingOccurrencesOfString(Config.firebaseUrl + "/", withString: "")
    let parts = path.componentsSeparatedByString("/")
    let root = parts.first?.lowercaseString
    var obj:GameObject! = nil
    
    if root == "players" && !objId.hasSuffix(Account.playerID) {
      obj = Player(playerID: objId)
    }
    
    if (obj == nil) {
      // We don't error out because this is frequently used in chains
      // objects might not always exist, if data is in a suboptimal state
      return Promise<GameObject!>(nil)
    }
    else {
      return obj.loading.then { (snapshot) -> Promise<GameObject!> in
        return obj.draw()
      }
    }
  }
}
