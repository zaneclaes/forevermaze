//
//  Mobile.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation

enum Direction: Int {
  case N,NE,E,SE,S,SW,W,NW

  var description:String {
    switch self {
    case N: return "North"
    case NE:return "North East"
    case E: return "East"
    case SE:return "South East"
    case S: return "South"
    case SW:return "South West"
    case W: return "West"
    case NW:return "North West"
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

  init?(degrees: Int) {
    let degreesPerDirection = Int(360 / 8)
    let rotatedDegrees = degrees + degreesPerDirection / 2
    let raw = Int(rotatedDegrees / degreesPerDirection)
    self.init(rawValue: raw)
  }
}

class Mobile : GameObject {

  private dynamic var dir:Int = 0

  var direction:Direction {
    set { self.dir = newValue.rawValue          }
    get { return Direction(rawValue: self.dir)! }
  }

  func move(xDist: Int, yDist: Int) {
    self.position = self.position + (xDist, yDist)
  }

  func step(direction: Direction) {
    let (x,y) = direction.amount
    self.move(x, yDist: y)
  }

  func step() {
    self.step(self.direction)
  }
}
