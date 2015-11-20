//
//  Coordinate.swift
//  ForeverMaze
//
//  Created by Zane Claes on 1/18/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import Foundation
import SpriteKit

/************************************************************************
 * Coordinate
 * Provides a convenient interface for referring to a position on the map
 * Translates between positions (UInt) and indicies (Int)
 * Indicies are useful for wraparound data
 ***********************************************************************/
func + (p1: Coordinate, p2: Coordinate) -> Coordinate {
  return Coordinate(xIndex: p1.xIndex + p2.xIndex, yIndex: p1.yIndex + p2.yIndex)
}
func - (p1: Coordinate, p2: Coordinate) -> Coordinate {
  return Coordinate(xIndex: p1.xIndex - p2.xIndex, yIndex: p1.yIndex - p2.yIndex)
}
func + (p1: Coordinate, p2: (Int, Int)) -> Coordinate {
  return Coordinate(xIndex: p1.xIndex + p2.0, yIndex: p1.yIndex + p2.1)
}
func - (p1: Coordinate, p2: (Int, Int)) -> Coordinate {
  return Coordinate(xIndex: p1.xIndex - p2.0, yIndex: p1.yIndex - p2.1)
}

struct Coordinate : CustomStringConvertible, Hashable {
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
  
  func willWrapAroundWorldX(newPos: Coordinate, worldSize: MapSize, threshold: UInt) -> Bool {
    return (newPos.x < threshold && self.x >= worldSize.width - threshold) ||
      (newPos.x >= worldSize.width - threshold && self.x < threshold)
  }
  
  func willWrapAroundWorldY(newPos: Coordinate, worldSize: MapSize, threshold: UInt) -> Bool {
    return (newPos.y < threshold && self.y >= worldSize.height - threshold) ||
      (newPos.y >= worldSize.height - threshold && self.y < threshold)
  }
  
  func willWrapAroundWorld(newPos: Coordinate, worldSize: MapSize, threshold: UInt) -> Bool {
    //let wrapX = (newPos.x == 0 && self.x == worldSize.width - 1) || (newPos.x == worldSize.width - 1 && self.x == 0)
    //let wrapY = (newPos.y == 0 && self.y == worldSize.height - 1) || (newPos.y == worldSize.height - 1 && self.y == 0)
    return self.willWrapAroundWorldX(newPos, worldSize: worldSize, threshold: threshold) ||
      self.willWrapAroundWorldY(newPos, worldSize: worldSize, threshold: threshold)
  }
  
  func getDistance(to: Coordinate) -> UInt {
    return UInt(hypotf(Float(self.x) - Float(to.x), Float(self.y) - Float(to.y)))
  }
  
  func getDirection(to: Coordinate) -> Direction {
    let threshold:UInt = 10
    let worldSize = Config.worldSize
    
    var distX = Int(self.x) - Int(to.x)
    if (to.x < threshold && self.x >= worldSize.width - threshold) {
      distX = -1 * (Int(worldSize.width) - distX)
    }
    else if (to.x >= worldSize.width - threshold && self.x < threshold) {
      distX = (Int(worldSize.width) + distX)
    }
    
    var distY = Int(self.y) - Int(to.y)
    if (to.y < threshold && self.y >= worldSize.height - threshold) {
      distY = -1 * (Int(worldSize.height) - distY)
    }
    else if (to.y >= worldSize.height - threshold && self.y < threshold) {
      distY = (Int(worldSize.height) + distY)
    }
    
    if abs(distX) > abs(distY) {
      return distX > 0 ? .W : .E
    }
    else {
      return distY > 0 ? .S : .N
    }
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
  
  init(desc: String) {
    let parts = desc.componentsSeparatedByString("x")
    self.x = UInt(parts[0])!
    self.y = UInt(parts[1])!
  }
}
func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
  return lhs.x == rhs.x && lhs.y == rhs.y
}