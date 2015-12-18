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

enum Direction: Int {
  case N,E,S,W

  var description:String {
    switch self {
    case N: return "N"
    case E: return "E"
    case S: return "S"
    case W: return "W"
    }
  }

  var amount:(Int, Int) {
    switch self {
    case N: return (0,1)
    case E: return (1,0)
    case S: return (0,-1)
    case W: return (-1,0)
    }
  }

  static var directions:Array<Direction> {
    return [N,E,S,W]
  }

  init?(degrees: Int) {
    let degreesPerDirection = Double(360 / Direction.directions.count)
    var rotatedDegrees = Double(degrees)
    rotatedDegrees = rotatedDegrees > 360 ? (rotatedDegrees - 360) : rotatedDegrees
    rotatedDegrees = rotatedDegrees < 0 ? (rotatedDegrees + 360) : rotatedDegrees
    let raw = Int(floor(rotatedDegrees / degreesPerDirection))
    self.init(rawValue: raw)
  }
}

class GameObject : GameSprite {
  // Lookup cache for all gameObjects in the map, on ID
  static var textureCache:[String:SKTexture] = [:]

  private dynamic var x: UInt = 0
  private dynamic var y: UInt = 0

  override init(snapshot: FDataSnapshot!) {
    super.init(snapshot: snapshot)
    self.sprite = SKSpriteNode(imageNamed: assetName)
  }
  /**
   * Write all the missing SKTextures into the textureCache 
   * Also preload them from disk to avoid any later flickering
   */
  func cacheTextures() -> Promise<GameObject!> {
    var textures = Array<SKTexture>()
    for dir in Direction.directions {
      let textureName = self.assetPrefix + dir.description.lowercaseString
      if (GameObject.textureCache[textureName] != nil) {
        continue
      }
      let tex = SKTexture(imageNamed: textureName)
      GameObject.textureCache[textureName] = tex
      textures.append(tex)
    }
    if textures.count <= 0 {
      return Promise<GameObject!>(self)
    }
    else {
      return Promise { fulfill, reject in
        SKTexture.preloadTextures(textures) { () -> Void in
          fulfill(self)
        }
      }
    }
  }

  override func onPropertyChangedRemotely(property: String, oldValue: AnyObject) {
    if property == "x" || property == "y" {
      self.gameScene?.onObjectMoved(self)
    }
  }

  var assetPrefix:String {
    return "iso_3d_droid_"
  }

  var assetName:String {
    return self.assetPrefix + self.direction.description.lowercaseString
  }

  var movememntTime:NSTimeInterval {
    return Config.stepTime
  }

  private func updateSpriteTexture() {
    self.sprite.texture = GameObject.textureCache[assetName]
    if self.sprite.texture?.size() == CGSizeZero || self.sprite.texture == nil {
      DDLogError("Texture Error: \(GameObject.textureCache)")
    }
  }

  // `dir` is backed by Firebase, the primitive type which supports direction
  private dynamic var dir:Int = 0 {
    didSet {
      if oldValue != self.dir {
        self.updateSpriteTexture()
      }
    }
  }

  var direction:Direction {
    set {
      if self.dir != newValue.rawValue {
        self.dir = newValue.rawValue
        self.updateSpriteTexture()
      }
    }
    get {
      return Direction(rawValue: clamp(self.dir, lower: 0, upper: Direction.directions.count - 1))!
    }
  }

  var size: MapSize {
    return MapSize(width: 1, height: 1)
  }

  var position: MapPosition {
    set {
      self.gameScene?.tiles[self.position.description]?.removeObject(self)
      self.x = newValue.x
      self.y = newValue.y
      self.gameScene?.tiles[self.position.description]?.addObject(self)
    }
    get {
      return MapPosition(x: self.x, y: self.y)
    }
  }

  var box: MapBox {
    return MapBox(origin: self.position, size: self.size)
  }

  var id: String {
    return self.connection.description
      .stringByReplacingOccurrencesOfString(Config.firebaseUrl, withString: "")
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
      obj = Player(playerID: objId, snapshot: snapshot)
    }
    
    if (obj == nil) {
      // We don't error out because this is frequently used in chains
      // objects might not always exist, if data is in a suboptimal state
      return Promise<GameObject!>(nil)
    }
    else {
      // Cache the object so we can find it later easily
      return obj.cacheTextures()
    }
  }
  /**
   * Cleanup also uncaches textures from the static textureCache when they're not needed.
   */
  override func cleanup() {
    guard self.gameScene != nil else {
      super.cleanup()
      return
    }
    var texturesStillInUse = self.assetPrefix == Account.player?.assetPrefix
    for (_, obj) in (self.gameScene?.objects)! {
      if obj.assetPrefix == self.assetPrefix {
        texturesStillInUse = true
        break
      }
    }
    if !texturesStillInUse {
      let keys = GameObject.textureCache.keys
      for key in keys {
        if key.hasPrefix(self.assetPrefix) {
          GameObject.textureCache.removeValueForKey(key)
        }
      }
    }
    super.cleanup()
  }
}
