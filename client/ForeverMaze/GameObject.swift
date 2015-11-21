//
//  WorldObject.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

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
}

class GameObject : GameSprite {
}
