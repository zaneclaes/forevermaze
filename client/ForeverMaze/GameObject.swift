//
//  WorldObject.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

class GameObject : GameSprite {
  private dynamic var x: UInt = 0
  private dynamic var y: UInt = 0
  private dynamic var width: UInt = 1
  private dynamic var height: UInt = 1

  override var firebaseProperties:[String] {
    return super.firebaseProperties + ["x","y","width","height"]
  }

  var size: MapSize {
    return MapSize(width: max(1, self.width), height: max(1, self.height))
  }

  var position: MapPosition {
    set {
      self.x = newValue.x
      self.y = newValue.y
    }
    get {
      return MapPosition(x: self.x, y: self.y)
    }
  }

  var box: MapBox {
    return MapBox(origin: self.position, size: self.size)
  }
}
