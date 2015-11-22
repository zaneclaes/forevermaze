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

class GameScene: SKScene {
  override func didMoveToView(view: SKView) {
    let label = SKLabelNode(text: "Loading World...")
    label.color = SKColor.whiteColor()
    label.position = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    self.addChild(label)

    Map.world.load().then { (map) -> Void in
      label.removeFromParent()
    }.error { (error) -> Void in
      label.text = "\(error)"
      DDLogError("World Error \(error)")
    }

    let tex = SKSpriteNode(imageNamed: "droid_e")
    tex.position = CGPointMake(100, 200)
    self.addChild(tex)
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if Account.current.isLoggedIn {
      Account.current.logout()
    }
    else {
      Account.current.login().then { (userId) -> Void in
        DDLogInfo("TOKEN \(userId)")
      }.error { (error) -> Void in
        DDLogInfo("LOGIN ERR \(error)")
      }
    }
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
}
