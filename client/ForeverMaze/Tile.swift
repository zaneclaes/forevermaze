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
import CocoaLumberjack

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
  static let assetName = "iso_3d_ground"
  static let texture = SKTexture(imageNamed: Tile.assetName)

  let position: MapPosition
  private dynamic var e:Int = 0
  dynamic var objectIds:Array<String> = []

  init(position: MapPosition, snapshot: FDataSnapshot) {
    self.position = position
    super.init(snapshot: snapshot)
    self.sprite = SKSpriteNode(texture: Tile.texture)
    self.sprite.color = self.emotion.color
    self.sprite.colorBlendFactor = 1.0

    let label = SKLabelNode(text: self.position.description)
    label.color = SKColor.blackColor()
    label.fontName = "AvenirNext-Bold"
    label.fontSize = 12
    label.zPosition = 1
    label.position = CGPoint(x: self.sprite.size.width/2+1, y: self.sprite.size.height/4-1)
    self.sprite.addChild(label)
  }

  override func onPropertyChangedRemotely(property: String, oldValue: AnyObject) {
    if property == "objectIds" {
      let oldObjectIds = Set(oldValue as! Array<String>)
      let addedObjectIds = Set(self.objectIds).subtract(oldObjectIds)
      let removedObjectIds = oldObjectIds.subtract(self.objectIds)
      let changedObjectIds = addedObjectIds.union(removedObjectIds)
      self.gameScene?.onObjectsIdsMoved(changedObjectIds)
    }
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

  func scrubObjects() {
    var objIds = Array<String>()
    var changed = false
    for objId in self.objectIds {
      let obj = GameObject.cache[objId]
      if obj != nil && obj?.position.x != self.position.x && obj?.position.y != self.position.y {
        DDLogWarn("Scrubbing \(objId) from \(self) because it has moved.")
        changed = true
      }
      else {
        objIds.append(objId)
      }
    }
    if changed {
      self.objectIds = objIds
    }
  }

  var emotion: Emotion {
    return Emotion(rawValue: self.e)!
  }

  override var description:String {
    return "<Tile \(position.x)x\(position.y)>: \(emotion)"
  }
  
  private var promiseLoad:Promise<Void>? = nil
  var loaded: Bool {
    return (promiseLoad?.resolved)!
  }

  func loadObjects() -> Promise<Void> {
    if promiseLoad == nil {
      promiseLoad = Data.loadObjects(self.objectIds)
      promiseLoad!.then { () -> Void in
        self.scrubObjects()
      }
    }
    return promiseLoad!
  }
}
