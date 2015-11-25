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
    super.init(mapSize: Config.worldSize, size: size)
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
    for i in 0..<32 {
      for j in 0..<32 {
        let tile = Map.tiles[(Account.player?.position)!]
        let direction = Direction(rawValue: 0)!
        let point = point2DToIso(CGPoint(x: (j*tileSize.width), y: -(i*tileSize.height)))
        placeTileIso(tile, direction:direction, position:point)
      }
    }
  }

  /*Map.rebuild().then { () -> Void in
  DDLogInfo("Rebuilt World")
  }.error { (error) -> Void in
  DDLogError("World Error \(error)")
  }*/

  override func update(currentTime: CFTimeInterval) {
    let dir = self.dPadDirection
    if dir != nil {
      Account.player?.direction = dir!
      Account.player?.step()
      Map.load(Account.player!.position)
      DDLogInfo("\(Account.player!)")
    }
    super.update(currentTime)
  }
}
