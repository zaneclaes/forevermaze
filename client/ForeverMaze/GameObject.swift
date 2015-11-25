//
//  WorldObject.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase
import PromiseKit

class GameObject : GameSprite {
  // Lookup cache for all gameSprites in the map, on ID
  static var cache:[String:GameSprite] = [:]

  private dynamic var x: UInt = 0
  private dynamic var y: UInt = 0
  private dynamic var width: UInt = 1
  private dynamic var height: UInt = 1

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
      let type = snapshot.childSnapshotForPath("type").value as! String
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
}
