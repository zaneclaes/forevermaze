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

enum Direction: Int {
  case N,NE,E,SE,S,SW,W,NW

  var description:String {
    switch self {
    case N: return "N"
    case NE:return "NE"
    case E: return "E"
    case SE:return "SE"
    case S: return "S"
    case SW:return "SW"
    case W: return "W"
    case NW:return "NW"
    }
  }

  var amount:(Int, Int) {
    switch self {
    case N: return (0,1)
    case NE:return (1,1)
    case E: return (1,0)
    case SE:return (1,-1)
    case S: return (0,-1)
    case SW:return (-1,-1)
    case W: return (-1,0)
    case NW:return (-1,1)
    }
  }

  static var directions:Array<Direction> {
    return [N,NE,E,SE,S,SW,W,NW]
  }

  init?(degrees: Int) {
    let degreesPerDirection = Double(360 / 8)
    var rotatedDegrees = Double(degrees) - degreesPerDirection/2
    rotatedDegrees = rotatedDegrees > 360 ? (rotatedDegrees - 360) : rotatedDegrees
    rotatedDegrees = rotatedDegrees < 0 ? (rotatedDegrees + 360) : rotatedDegrees
    let raw = Int(floor(rotatedDegrees / degreesPerDirection))
    self.init(rawValue: raw)
  }
}

class GameObject : GameSprite {
  // Lookup cache for all gameSprites in the map, on ID
  static var cache:[String:GameObject] = [:]
  static var textureCache:[String:SKTexture] = [:]

  private dynamic var x: UInt = 0
  private dynamic var y: UInt = 0
  private dynamic var width: UInt = 1
  private dynamic var height: UInt = 1
  private dynamic var dir:Int = 0

  override init(snapshot: FDataSnapshot!) {
    super.init(snapshot: snapshot)
    // Build texture cache...
    self.sprite = SKSpriteNode(imageNamed: assetName)
    for dir in Direction.directions {
      let textureName = self.assetPrefix + dir.description.lowercaseString
      GameObject.textureCache[textureName] = SKTexture(imageNamed: textureName)
    }
  }

  var assetPrefix:String {
    return "iso_3d_droid_"
  }

  var assetName:String {
    return self.assetPrefix + self.direction.description.lowercaseString
  }

  var direction:Direction {
    set {
      if self.dir != newValue.rawValue {
        self.dir = newValue.rawValue
        self.sprite.texture = GameObject.textureCache[assetName]
      }
    }
    get { return Direction(rawValue: self.dir)! }
  }

  var size: MapSize {
    return MapSize(width: max(1, self.width), height: max(1, self.height))
  }

  var position: MapPosition {
    set {
      Map.tiles[self.position]?.removeObject(self)
      self.x = newValue.x
      self.y = newValue.y
      Map.tiles[self.position]?.addObject(self)
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
  static func factory(snapshot: FDataSnapshot) -> Promise<GameObject!> {
    return Promise { fulfill, reject in
      let path = snapshot.ref.description.stringByReplacingOccurrencesOfString(Config.firebaseUrl + "/", withString: "")
      let parts = path.componentsSeparatedByString("/")
      let root = parts.first?.lowercaseString
      let type = snapshot.childSnapshotForPath("type").value as? String
      let objId:String! = parts.count > 1 ? parts[1] : nil
      var obj:GameObject! = nil
      if objId == nil {
        fulfill(nil)
        return
      }

      if root == "players" && objId != Account.playerID {
        obj = Player(playerID: objId, snapshot: snapshot)
      }
      else if root == "objects" {
        if type == "tree" {

        }
      }

      // Cache the object so we can find it later easily
      if obj != nil {
        cache[obj.id] = obj
      }

      // We don't error out because this is frequently used in chains
      // objects might not always exist, if data is in a suboptimal state
      fulfill(obj)
    }
  }

  /**
   * Cleanup also uncaches textures from the static textureCache when they're not needed.
   */
  override func cleanup() {
    var texturesStillInUse = false
    for (_, obj) in GameObject.cache {
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
