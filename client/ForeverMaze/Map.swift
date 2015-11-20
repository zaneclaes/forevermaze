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
 * Combination of Coordinate + MapSize that can do basic logic, like intersection
 ***********************************************************************/
struct MapBox : CustomStringConvertible {
  let origin: Coordinate
  let size: MapSize
  let center: Coordinate
  
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
  func contains(coordinate: Coordinate) -> Bool {
    let rects = testRects
    let point = CGPointMake(CGFloat(coordinate.x), CGFloat(coordinate.y))
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
  
  var destination:Coordinate {
    return Coordinate(xIndex: origin.xIndex + Int(size.width - 1), yIndex: origin.yIndex + Int(size.height - 1))
  }

  var description:String {
    return "<\(self.dynamicType)>: [\(origin)] [\(size)] [\(destination)]"
  }

  init(origin: Coordinate, size:MapSize) {
    self.origin = origin
    self.size = size
    self.center = Coordinate(xIndex: origin.xIndex + Int(size.width/2), yIndex: origin.yIndex + Int(size.height/2))
  }

  init(center: Coordinate, size:MapSize) {
    self.origin = Coordinate(
      xIndex: center.xIndex - Int(floorf(Float(size.width)/2.0)),
      yIndex: center.yIndex - Int(floorf(Float(size.height)/2.0))
    )
    self.center = center
    self.size = size
  }
}
