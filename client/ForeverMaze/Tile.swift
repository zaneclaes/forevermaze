//
//  Tile.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import Firebase
import PromiseKit

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

  var color:UIColor {
    switch self {
    case Happiness: return .yellowColor()
    case Sadness:   return .blueColor()
    case Anger:     return .redColor()
    case Fear:      return .greenColor()
    }
  }

  static func random() -> Emotion {
    return Emotion(rawValue: Int(arc4random_uniform(NumberOfEmotions)))!
  }
}

class Tile : GameSprite {

  let position: MapPosition
  private dynamic var e:Int = 0
  dynamic var objectIds:Array<String> = []

  init(position: MapPosition, snapshot: FDataSnapshot) {
    self.position = position
    super.init(snapshot: snapshot)
    self.sprite = SKSpriteNode(imageNamed: "iso_3d_ground")
    self.sprite.color = self.emotion.color
    self.sprite.colorBlendFactor = 1.0
  }

  func removeObject(obj: GameObject) {
    let idx = self.objectIds.indexOf(obj.id)
    if idx >= 0 {
      self.objectIds.removeAtIndex(idx!)
    }
  }

  func addObject(obj: GameObject) {
    self.objectIds.append(obj.id)
  }

  var emotion: Emotion {
    return Emotion(rawValue: self.e)!
  }

  override var description:String {
    return "<Tile \(position.x)x\(position.y)>: \(emotion)"
  }

  var loaded: Bool {
    for id in self.objectIds {
      if GameObject.cache[id] == nil {
        return false
      }
    }
    return true
  }

  func loadObjects() -> Promise<Void> {
    return Data.loadObjects(self.objectIds)
  }
}
