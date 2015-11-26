//
//  GameScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright (c) 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import CocoaLumberjack

class GameScene: IsoScene {

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(size: CGSize) {
    super.init(mapBox: MapBox(center: (Account.player?.position)!, size: Config.screenTiles), size: size)
  }

  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)

    let label = SKLabelNode(text: "Loading World...")
    label.color = SKColor.whiteColor()
    label.position = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    self.addChild(label)

    Map.load(Account.player!.position).then { () -> Void in
      DDLogInfo("Loaded.")
      self.drawWorld()
      label.removeFromParent()
    }.error { (error) -> Void in
      label.text = "\(error)"
      DDLogError("World Error \(error)")
    }

    /*
    let tex = SKSpriteNode(imageNamed: "droid_e")
    tex.position = CGPointMake(100, 200)
    self.addChild(tex)*/
  }

  func drawWorld() {
    let center:MapPosition = (Account.player?.position)!
    let boundingBox:MapBox = MapBox(center: center, size: Config.screenTiles)
    for i in 0..<Int(Config.screenTiles.width) {
      for j in 0..<Int(Config.screenTiles.height) {
        let position = boundingBox.origin + (i,j)
        addTile(Map.tiles[position])
      }
    }
    addObject(Account.player!)
  }

  /*Map.rebuild().then { () -> Void in
  DDLogInfo("Rebuilt World")
  }.error { (error) -> Void in
  DDLogError("World Error \(error)")
  }*/

  func nextStep(force: Bool) {
    let dir = self.dPadDirection
    if dir == nil {
      return
    }
    let sprite = Account.player?.sprite
    let key = "move"
    if force || sprite?.actionForKey(key) == nil {

      var actions = Array<SKAction>()
      let pos = (Account.player?.position)! + dir!.amount
      let point = mapPositionToIsoPoint(pos)

      // First update the player
      actions.append(SKAction.runBlock({
        Account.player?.direction = dir!
        Account.player?.step()
        Map.load(Account.player!.position)
      }))

      // Then animate the movement
      let dist = Double(distance((sprite?.position)!, p2: point))
      actions.append(SKAction.moveTo(point, duration: dist * 0.01))

      // And finally call back into nextStep()
      actions.append(SKAction.runBlock({
        self.isoOcclusionZSort()
        self.nextStep(true)
      }))

      sprite?.runAction(SKAction.sequence(actions), withKey: key)
    }
  }

  override func update(currentTime: CFTimeInterval) {
    self.nextStep(false)
    super.update(currentTime)
  }
}
