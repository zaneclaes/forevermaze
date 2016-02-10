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

enum TileState: Int {
  case Online, Unlocked, Unlockable, Locked
}

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
    let m:CGFloat = 0.25
    return UIColor(red: m, green: m, blue: m, alpha: 1)
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
  static let unlockSound = SKAction.playSoundFileNamed("unlock.caf", waitForCompletion: false)
  
  let coordinate: Coordinate
  private dynamic var e:Int = 0
  dynamic var objectIds:Array<String> = []
  let icon = SKSpriteNode(texture: Config.worldAtlas.textureNamed("icon_happiness"))
  private var dropshadow:SKSpriteNode?
  private let state: TileState
  private var _emotion:Emotion

  init(coordinate: Coordinate, state: TileState) {
    self.coordinate = coordinate
    self.state = state
    _emotion = Emotion.random()
    super.init(firebasePath: state == .Online ? "/tiles/\(coordinate.x)x\(coordinate.y)" : nil)
    
    sprite.colorBlendFactor = 1.0
    updateTexture()
    sprite.xScale = 1
    sprite.yScale = 1
    sprite.size = sprite.texture!.size()
    assignScale()
    updateLockedState()
    if state == .Online {
      loading.then { (snapshot) -> Void in
        self.updateTexture()
        self.updateLockedState()
      }
    }
    else {
      loadFulfill(nil)
    }
    
    icon.hidden = true
    icon.position = CGPointMake(0,Tile.yOrigin + self.icon.frame.size.height/3)
    sprite.addChild(self.icon)
  }
  
  var hasDropshadow:Bool = false {
    didSet {
      if hasDropshadow {
        if dropshadow == nil {
          dropshadow = SKSpriteNode(texture: sprite.texture)
          dropshadow!.color = .blackColor()
          dropshadow!.alpha = 0.8
          dropshadow!.zPosition = -0.1
          dropshadow!.position = CGPointMake(0, -12)
          dropshadow!.colorBlendFactor = 1.0
          sprite.addChild(dropshadow!)
        }
        dropshadow!.hidden = false
      }
      else {
        if dropshadow != nil {
          dropshadow!.hidden = true
        }
      }
    }
  }
  
  var unlocked:Bool {
    if state == .Online && Account.player != nil {
      return Account.player!.hasUnlockedTileAt(self.coordinate)
    }
    else {
      return state == .Unlocked
    }
  }

  var unlockable:Bool {
    if state == .Online && Account.player != nil {
      return Account.player!.canUnlockTile(self)
    }
    else {
      return state == .Unlockable
    }
  }
  
  func updateTexture() {
    sprite.texture = Config.worldAtlas.textureNamed("tile_\(self.emotion.description.lowercaseString)")
    icon.texture = Config.worldAtlas.textureNamed("icon_\(self.emotion.description.lowercaseString)")
    if dropshadow != nil {
      dropshadow!.texture = sprite.texture
    }
    assignScale()
  }

  func updateLockedState() {
    if unlocked {
      sprite.color = .whiteColor()
      icon.hidden = true
    }
    else if unlockable {
      sprite.color = self.emotion.lockedColor
      icon.hidden = false
    }
    else {
      sprite.color = UIColor.clearColor()
      icon.hidden = true
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
      if state == .Online {
        self.e = newValue.rawValue
      }
      else {
        _emotion = newValue
      }
      self.updateTexture()
      self.updateLockedState()
    }
    get {
      return state == .Online ? Emotion(rawValue: self.e)! : _emotion
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
    sprite.runAction(Tile.unlockSound)
  }

  override var description:String {
    return "<Tile \(coordinate.x)x\(coordinate.y)>: \(emotion)"
  }
}
