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
    super.init(center: (Account.player?.position)!, worldSize: Config.worldSize, size: size)
  }

  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)

    let label = SKLabelNode(text: "Loading World...")
    label.color = SKColor.whiteColor()
    label.position = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    self.addChild(label)

    Map.load(Account.player!.position).then { () -> Void in
      DDLogInfo("Loaded.")

      self.center = (Account.player?.position)!
      self.drawWorld()

      self.addObject(Account.player!)
      self.playerSprite = Account.player!.sprite

      label.removeFromParent()
    }.error { (error) -> Void in
      label.text = "\(error)"
      DDLogError("World Error \(error)")
    }
  }

  /*Map.rebuild().then { () -> Void in
  DDLogInfo("Rebuilt World")
  }.error { (error) -> Void in
  DDLogError("World Error \(error)")
  }*/
}
