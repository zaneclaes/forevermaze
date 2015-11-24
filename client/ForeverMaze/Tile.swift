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

  let x: UInt
  let y: UInt
  dynamic var e:Int

  init(x: UInt, y: UInt, snapshot: FDataSnapshot) {
    self.x = x
    self.y = y
    self.e = 0
    super.init(snapshot: snapshot)
  }

  func randomizeEmotion() {
    self.connection.childByAppendingPath("e").setValue(Emotion.random().rawValue)
  }

  var emotion: Emotion {
    return Emotion(rawValue: self.e)!
  }

  /*
  static func randomizeMap(size: UInt) {
    for (var x: UInt = 0; x < size; x++) {
      for (var y: UInt = 0; y < size; y++) {
        let tile: Tile = Tile(x: x, y: y)
        tile.randomizeEmotion()
      }
    }
  }*/

}
