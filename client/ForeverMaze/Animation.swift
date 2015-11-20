//
//  Animation.swift
//  ForeverMaze
//
//  Created by Zane Claes on 1/18/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit

enum AnimationGroup: Int {
  case Idle,Walking
  
  var description:String {
    switch self {
    case Idle:    return "idle"
    case Walking: return "walking"
    }
  }
  
  var timePerFrame:Double {
    switch self {
    case Idle:    return 0.07
    case Walking: return 0.02
    }
  }
  
  static var groups:Array<AnimationGroup> {
    return [Idle,Walking]
  }
}

class Animation {
  static var cache:[String:Animation] = [:]
  static let actionKey = "animation"
  static let movementKey = "move"
  static let unlockKey = "unlock"
  
  private let atlas:SKTextureAtlas
  private var frames = [String:Array<SKTexture>]()
  
  init(name: String) {
    atlas = SKTextureAtlas(named: name)
    
    let textureNames = atlas.textureNames.sort { (a, b) -> Bool in
      let v1 = Int(a.componentsSeparatedByString("_").last!.componentsSeparatedByString(".").first!)
      let v2 = Int(b.componentsSeparatedByString("_").last!.componentsSeparatedByString(".").first!)
      return v1 < v2
    }
    for textureName in textureNames {
      if textureName.rangeOfString("@") != nil {
        continue
      }
      let parts = textureName.componentsSeparatedByString("_")
      let key = "\(parts[1])_\(parts[2])"
      if frames[key] == nil {
        frames[key] = Array<SKTexture>()
      }
      let texture = atlas.textureNamed(textureName.componentsSeparatedByString(".").first!)
      frames[key]!.append(texture)
    }
  }
  
  func getKey(group: AnimationGroup, direction: Direction) -> String {
    return "\(group.description.lowercaseString)_\(Animation.normalizeDirection(direction).description.lowercaseString)"
  }
  
  func createSprite(group: AnimationGroup, direction: Direction) -> SKSpriteNode {
    let key = getKey(group, direction: direction)
    let textures = frames[key]!
    let node = SKSpriteNode(texture: textures.first)
    node.anchorPoint = CGPointMake(0.5, 0)
    return node
  }
  
  func getAction(group: AnimationGroup, direction: Direction, speed: Double) -> SKAction {
    let key = getKey(group, direction: direction)
    return SKAction.repeatActionForever(
      SKAction.animateWithTextures(frames[key]!,
        timePerFrame: group.timePerFrame / speed,
        resize: false,
        restore: true)
    )
  }
  
  func cacheTextures() -> Promise<Animation> {
    var textures = Array<SKTexture>()
    for set in frames.values {
      for frame in set {
        textures.append(frame)
      }
    }
    return Promise { fulfill, reject in
      SKTexture.preloadTextures(textures) { () -> Void in
        fulfill(self)
      }
    }
  }
  
  static func normalizeDirection(dir: Direction) -> Direction {
    if dir == .S || dir == .E {
      return .S
    }
    else {
      return .N
    }
  }
  
  static func preload(name: String) -> Promise<Animation> {
    guard cache[name] == nil else {
      return Promise<Animation>(cache[name]!)
    }
    cache[name] = Animation(name: name)
    return cache[name]!.cacheTextures()
  }
}
