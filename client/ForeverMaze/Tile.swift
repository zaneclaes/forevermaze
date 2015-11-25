//
//  Tile.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

let NumberOfEmotions: UInt32 = 4

enum Emotion: Int {
  case Happiness, Sadness, Anger, Fear

  var description:String {
    switch self {
    case Happiness: return "Happiness"
    case Sadness:   return "Sadness"
    case Anger:     return "Anger"
    case Fear:      return "Fear"
    }
  }

  static func random() -> Emotion {
    return Emotion(rawValue: Int(arc4random_uniform(NumberOfEmotions)))!
  }
}

class Tile : GameSprite {

  let position: MapPosition
  dynamic var e:Int = 0

  init(position: MapPosition, snapshot: FDataSnapshot) {
    self.position = position
    super.init(snapshot: snapshot)
  }

  var emotion: Emotion {
    return Emotion(rawValue: self.e)!
  }

  override var description:String {
    return "<Tile \(position.x)x\(position.y)>: \(emotion)"
  }
}
