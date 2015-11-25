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
      self.placeAllTilesIso()
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

  override func placeAllTilesIso() {
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

  override func update(currentTime: CFTimeInterval) {
    let dir = self.dPadDirection
    if dir != nil {
      //var actions = Array<SKAction>()
      //actions.append(SKAction.runBlock({
      //}))
      Account.player?.direction = dir!

      //Account.player?.sprite.removeAllActions()
      //Account.player?.sprite.runAction(SKAction.sequence(actions))

      Map.load(Account.player!.position)
      DDLogInfo("\(Account.player!)")
    }
    super.update(currentTime)
  }
}
