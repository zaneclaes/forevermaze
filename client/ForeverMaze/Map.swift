//
//  Map.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase
import PromiseKit

/************************************************************************
 * MapPosition
 * Provides a convenient interface for referring to a position on the map
 * Translates between positions (UInt) and indicies (Int)
 * Indicies are useful for wraparound data
 ***********************************************************************/
struct MapPosition : CustomStringConvertible {
  var x: UInt
  var y: UInt

  func getIndicies() -> (Int, Int) {
    var x:Int = Int(self.x)
    var y:Int = Int(self.y)
    x = x >= Int(Config.worldSize.width) - Int(Config.screenTiles.width) ? (x - Int(Config.worldSize.width)) : x
    y = y >= Int(Config.worldSize.height) - Int(Config.screenTiles.height) ? (y - Int(Config.worldSize.height)) : y
    return (x, y)
  }

  var xIndex: Int {
    return self.getIndicies().0
  }

  var yIndex: Int {
    return self.getIndicies().1
  }

  var description:String {
    return "(\(x)x\(y))"
  }

  init(x: UInt, y: UInt) {
    self.x = x
    self.y = y
  }

  init(xIndex: Int, yIndex: Int) {
    let xPos = xIndex < 0 ? UInt(Int(Config.worldSize.width) + xIndex) : UInt(xIndex)
    self.x = xPos >= UInt(Config.worldSize.width) ? (xPos - UInt(Config.worldSize.width)) : xPos

    let yPos = yIndex < 0 ? UInt(Int(Config.worldSize.height) + yIndex) : UInt(yIndex)
    self.y = yPos >= UInt(Config.worldSize.height) ? (yPos - UInt(Config.worldSize.height)) : yPos
  }
}
/************************************************************************
 * MapSize
 ***********************************************************************/
struct MapSize : CustomStringConvertible {
  var width: UInt
  let height: UInt

  var description:String {
    return "[\(width)x\(height)]"
  }

  init(width: UInt, height: UInt) {
    self.width = width
    self.height = height
  }
}
/************************************************************************
 * MapBox
 * Combination of MapPosition + MapSize that can do basic logic, like intersection
 ***********************************************************************/
struct MapBox : CustomStringConvertible {
  let origin: MapPosition
  let size: MapSize

  // Takes in a position, but first denormalizes into integers for easy comparison
  func contains(position: MapPosition) -> Bool {
    let xStop = self.origin.xIndex + Int(self.size.width)
    let yStop = self.origin.yIndex + Int(self.size.height)
    return position.xIndex >= self.origin.xIndex && position.xIndex <= xStop &&
            position.yIndex >= self.origin.yIndex && position.yIndex <= yStop
  }

  var description:String {
    return "<\(self.dynamicType)>: [\(origin.x)x\(origin.y)] [\(size.width)x\(size.height)]"
  }

  init(origin: MapPosition, size:MapSize) {
    self.origin = origin
    self.size = size
  }

  init(center: MapPosition, size:MapSize) {
    self.origin = MapPosition(
      xIndex: center.xIndex - Int(size.width/2),
      yIndex: center.yIndex - Int(size.height/2)
    )
    self.size = size
  }
}
/************************************************************************
 * Main Map Interface
 ***********************************************************************/
class Map {
  static var tiles: [String: Tile] = [:]

  static func getTile(position: MapPosition) -> Tile! {
    return tiles["\(position.x)x\(position.y)"]
  }
  /**
   * Load the map into the tiles array based upon Config.screenTiles
   * If a tile already exists, it does not reload it.
   * If a tile is now out-of-bounds, it evicts it.
   */
  static func load(center: MapPosition) -> Promise<Void> {
    let boundingBox:MapBox = MapBox(center: center, size: Config.screenTiles)
    var removedObjectIds = Set<String>()
    //
    // Evict any old tiles...
    //
    let keys = tiles.keys
    for key in keys {
      let tile = tiles[key]
      if !boundingBox.contains(tile!.position) {
        for objectId in tile!.objectIds {
          removedObjectIds.insert(objectId)
        }
        tiles.removeValueForKey(key)
      }
    }
    //
    // Now load any new tiles...
    //
    var promises = Array<Promise<Void>>()
    for (var x = boundingBox.origin.xIndex; x < Int(boundingBox.size.width) + boundingBox.origin.xIndex; x++) {
      for (var y = boundingBox.origin.yIndex; y < Int(boundingBox.size.height) + boundingBox.origin.yIndex; y++) {
        let pos = MapPosition(xIndex: x, yIndex: y)
        let key = "\(pos.x)x\(pos.y)"
        if tiles[key] != nil {
          continue
        }
        let promise = Data.loadSnapshot("/tiles/\(key)").then { (snapshot) -> Promise<Void> in
          let tile = Tile(position: pos, snapshot: snapshot)
          tiles[key] = tile
          for objectId in tile.objectIds {
            removedObjectIds.remove(objectId)
          }
          return tile.loadObjects()
        }
        promises.append(promise)
      }
    }
    //
    // Uncache + Cache objects
    //
    for id in removedObjectIds {
      GameObject.cache.removeValueForKey(id)
    }

    return when(promises)
  }
  /**
   * Reset & randomize the world
   */
  static func rebuild() -> Promise<Void> {
    let connection = Firebase(url: Config.firebaseUrl + "/tiles")
    var promises = Array<Promise<Void>>()
    for (var x: UInt = 0; x < UInt(Config.worldSize.width); x++) {
      for (var y: UInt = 0; y < UInt(Config.worldSize.height); y++) {
        let fb = connection.childByAppendingPath("\(x)x\(y)").childByAppendingPath("e")
        promises.append(fb.write(Emotion.random().rawValue))
      }
    }
    return when(promises)
  }
}
