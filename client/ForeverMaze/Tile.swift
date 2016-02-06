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

  var unlockedColor:UIColor {
    switch self {
    case Happiness: return .yellowColor()
    case Sadness:   return .cyanColor()
    case Anger:     return .redColor()
    case Fear:      return .greenColor()
    }
  }

  var emoji:String {
    switch self {
    case Happiness: return "😃"
    case Sadness:   return "😢"
    case Anger:     return "😡"
    case Fear:      return "😱"
    }
  }

  var lockedColor:UIColor {
    var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
    let m:CGFloat = 0.25
    self.unlockedColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return UIColor(colorLiteralRed: Float(r * m), green: Float(g * m), blue: Float(b * m), alpha: Float(a))
  }

  static var emotions:Array<Emotion> {
    return [Happiness,Sadness,Anger,Fear]
  }

  static func random() -> Emotion {
    return Emotion(rawValue: Int(arc4random_uniform(NumberOfEmotions)))!
  }
}

class Tile : GameStatic {
  static let size = (width:88, height:88)
  static let yOrigin:CGFloat = 68
  
  let coordinate: Coordinate
  private dynamic var e:Int = 0
  dynamic var objectIds:Array<String> = []
  let icon = SKSpriteNode(texture: Config.worldAtlas.textureNamed("icon_happiness"))
  private var _unlocked:Bool

  init(coordinate: Coordinate, unlocked: Bool) {
    self.coordinate = coordinate
    _unlocked = unlocked
    super.init(firebasePath: "/tiles/\(coordinate.x)x\(coordinate.y)")
    
    let emotion = Emotion.random()
    icon.texture = Config.worldAtlas.textureNamed("icon_\(emotion.description.lowercaseString)")
    self.sprite = SKSpriteNode(texture: Config.worldAtlas.textureNamed("tile_\(emotion.description.lowercaseString)"))
    self.sprite.colorBlendFactor = 1.0
    self.loading.then { (snapshot) -> Void in
      self.updateTexture()
      self.updateLockedState()
    }
    
    self.icon.hidden = true
    self.icon.position = CGPointMake(0,Tile.yOrigin + self.icon.frame.size.height/3)
    self.sprite.addChild(self.icon)
  }
  
  var unlocked:Bool {
    guard Account.player != nil else {
      return _unlocked
    }
    return Account.player!.hasUnlockedTileAt(self.coordinate)
  }

  var unlockable:Bool {
    guard Account.player != nil else {
      return true
    }
    return Account.player!.canUnlockTile(self)
  }
  
  func updateTexture() {
    self.sprite.texture = Config.worldAtlas.textureNamed("tile_\(self.emotion.description.lowercaseString)")
    self.icon.texture = Config.worldAtlas.textureNamed("icon_\(self.emotion.description.lowercaseString)")
    self.assignScale()
  }

  func updateLockedState() {
    if unlocked {
      self.sprite.color = .whiteColor()
      self.icon.hidden = true
    }
    else if unlockable {
      self.sprite.color = self.emotion.lockedColor
      self.icon.hidden = false
    }
    else {
      self.sprite.color = UIColor.clearColor()
      self.icon.hidden = true
    }
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
    guard obj.connection != nil else {
      // Depression and other local objects
      return
    }
    self.objectIds.append(obj.id)
  }

  func scrubObjects() {
    var objIds = Array<String>()
    var changed = false
    
    for objId in self.objectIds {
      let obj = self.gameScene?.objects[objId]
      if obj != nil && obj?.coordinate.x != self.coordinate.x && obj?.coordinate.y != self.coordinate.y {
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
    set {
      self.e = newValue.rawValue
      self.updateTexture()
      self.updateLockedState()
    }
    get {
      return Emotion(rawValue: self.e)!
    }
  }

  func playUnlockAnimation() {
    let path = NSBundle.mainBundle().pathForResource("unlock-\(self.emotion.description.lowercaseString)", ofType: "sks")!
    let particle = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as! SKEmitterNode
    particle.position = CGPointMake(0, CGFloat(Tile.size.height))
    particle.name = "unlockParticles"
    //particle.targetNode = self.gameScene
    particle.zPosition = 10000
    self.sprite.addChild(particle)
  }

  override var description:String {
    return "<Tile \(coordinate.x)x\(coordinate.y)>: \(emotion)"
  }
}
