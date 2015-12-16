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
import CocoaLumberjack

/************************************************************************
 * MapPosition
 * Provides a convenient interface for referring to a position on the map
 * Translates between positions (UInt) and indicies (Int)
 * Indicies are useful for wraparound data
 ***********************************************************************/
func + (p1: MapPosition, p2: MapPosition) -> MapPosition {
  return MapPosition(xIndex: p1.xIndex + p2.xIndex, yIndex: p1.yIndex + p2.yIndex)
}
func - (p1: MapPosition, p2: MapPosition) -> MapPosition {
  return MapPosition(xIndex: p1.xIndex - p2.xIndex, yIndex: p1.yIndex - p2.yIndex)
}
func + (p1: MapPosition, p2: (Int, Int)) -> MapPosition {
  return MapPosition(xIndex: p1.xIndex + p2.0, yIndex: p1.yIndex + p2.1)
}
func - (p1: MapPosition, p2: (Int, Int)) -> MapPosition {
  return MapPosition(xIndex: p1.xIndex - p2.0, yIndex: p1.yIndex - p2.1)
}

struct MapPosition : CustomStringConvertible, Hashable {
  var x: UInt
  var y: UInt

  func getIndicies() -> (Int, Int) {
    var x:Int = Int(self.x)
    var y:Int = Int(self.y)
    x = x >= Int(Config.worldSize.width) - Int(Config.screenTiles.width) ? (x - Int(Config.worldSize.width)) : x
    y = y >= Int(Config.worldSize.height) - Int(Config.screenTiles.height) ? (y - Int(Config.worldSize.height)) : y
    return (x, y)
  }

  var hashValue: Int {
    return self.description.hashValue
  }

  var xIndex: Int {
    return self.getIndicies().0
  }

  var yIndex: Int {
    return self.getIndicies().1
  }

  var description:String {
    return "\(x)x\(y)"
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
func ==(lhs: MapPosition, rhs: MapPosition) -> Bool {
  return lhs.x == rhs.x && lhs.y == rhs.y
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
  let center: MapPosition
  
  private var testRects:Array<CGRect> {
    // n.b., CGRectContainsPoint(CGRectMake(0,0,1,1),CGPointMake(1,1)) -> False
    let rectWidth = CGFloat(size.width)
    let rectHeight = CGFloat(size.height)
    
    var rects = [CGRectMake(CGFloat(origin.x), CGFloat(origin.y), rectWidth, rectHeight)]
    if wrapX {
      rects.append(CGRectMake(CGFloat(origin.xIndex), CGFloat(origin.y), rectWidth, rectHeight))
    }
    if wrapY {
      rects.append(CGRectMake(CGFloat(origin.x), CGFloat(origin.yIndex), rectWidth, rectHeight))
    }
    if wrapX && wrapY {
      rects.append(CGRectMake(CGFloat(origin.xIndex), CGFloat(origin.yIndex), rectWidth, rectHeight))
    }
    return rects
  }

  // Takes in a position, but first denormalizes into integers for easy comparison
  func contains(position: MapPosition) -> Bool {
    /*if (origin.x + size.width) >= UInt(CGFloat.max) || (origin.y + size.height) >= UInt(CGFloat.max) {
      DDLogError("World is too big.")
    }*/
    
    let rects = testRects
    let point = CGPointMake(CGFloat(position.x), CGFloat(position.y))
    for rect in rects {
      if CGRectContainsPoint(rect, point) {
        return true
      }
    }
    return false
  }
  
  var wrapX:Bool {
    return origin.x > (Config.worldSize.width - Config.screenTiles.width)
  }
  
  var wrapY:Bool {
    return origin.y > (Config.worldSize.height - Config.screenTiles.height)
  }
  
  var wraps:Bool {
    return wrapX || wrapY
  }
  
  var destination:MapPosition {
    return MapPosition(xIndex: origin.xIndex + Int(size.width - 1), yIndex: origin.yIndex + Int(size.height - 1))
  }

  var description:String {
    return "<\(self.dynamicType)>: [\(origin)] [\(size)] [\(destination)]"
  }

  init(origin: MapPosition, size:MapSize) {
    self.origin = origin
    self.size = size
    self.center = MapPosition(xIndex: origin.xIndex + Int(size.width/2), yIndex: origin.yIndex + Int(size.height/2))
  }

  init(center: MapPosition, size:MapSize) {
    self.origin = MapPosition(
      xIndex: center.xIndex - Int(floorf(Float(size.width)/2.0)),
      yIndex: center.yIndex - Int(floorf(Float(size.height)/2.0))
    )
    self.center = center
    self.size = size
  }
}
/************************************************************************
 * Main Map Interface
 ***********************************************************************/
class MapTiles {
  var cache: [String: Tile] = [:]

  func evict(key: String) {
    guard cache.keys.contains(key) else {
      return
    }
    cache.removeValueForKey(key)
  }

  func add(tile: Tile) {
    cache["\(tile.position.x)x\(tile.position.y)"] = tile
  }

  func contains(position: MapPosition) -> Bool {
    return self.cache.keys.contains("\(position.x)x\(position.y)")
  }

  subscript(position: MapPosition) -> Tile! {
    get { return self.cache["\(position.x)x\(position.y)"]        }
    set { self.cache["\(position.x)x\(position.y)"] = newValue    }
  }

  subscript(key: String) -> Tile! {
    return self.cache[key]
  }
}
class Map {
  static var tiles = MapTiles()
  static var loadingTiles = Set<String>()

  /**
   * Load the map into the tiles array based upon Config.screenTiles
   * If a tile already exists, it does not reload it.
   * If a tile is now out-of-bounds, it evicts it.
   */
  static func load(positions: Set<MapPosition>) -> Promise<Void> {
    var removedObjectIds = Set<String>()
    //
    // Evict any old tiles...
    //
    let keys = tiles.cache.keys
    for key in keys {
      let cachedTile = tiles[key]
      if cachedTile != nil && !positions.contains(cachedTile.position) {
        for objectId in cachedTile!.objectIds {
          removedObjectIds.insert(objectId)
        }
        tiles.evict(key)
        DDLogDebug("Evicting \(key)")
      }
    }
    //
    // Now load any new tiles...
    //
    var promises = Array<Promise<Void>>()
    for pos in positions {
      let key = "\(pos.x)x\(pos.y)"
      if tiles[pos] != nil || loadingTiles.contains(key) {
        continue
      }
      loadingTiles.insert(key)
      let promise = Data.loadSnapshot("/tiles/\(key)").then { (snapshot) -> Promise<Void> in
        let tile = Tile(position: pos, snapshot: snapshot)
        tiles.add(tile)
        loadingTiles.remove(key)
        for objectId in tile.objectIds {
          removedObjectIds.remove(objectId)
        }
        return Promise<Void>() // tile.loadObjects()
      }
      DDLogDebug("Caching \(key)")
      promises.append(promise)
    }
    //
    // Uncache + Cache objects, done as a sentinal so that the `remove` commands above can complete.
    //
    promises.append(Promise { fulfill, reject in
      for id in removedObjectIds {
        GameObject.cache.removeValueForKey(id)
      }
      fulfill()
    })
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
