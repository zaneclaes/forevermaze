//
//  AccountScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/22/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import CocoaLumberjack

class AccountScene: SKScene {
  override func didMoveToView(view: SKView) {
    self.backgroundColor = UIColor.blackColor()
    
    let label = SKLabelNode(text: "Checking Login...")
    label.color = SKColor.whiteColor()
    label.position = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    self.addChild(label)

    UIApplication.sharedApplication().networkActivityIndicatorVisible = true

    Config.setup().then { () -> Promise<LocalPlayer!> in
      return Account.resume()
    }.then { (player) -> Void in
      DDLogInfo("[PLAYER]: \(player)")
      if player != nil {
        self.pushGameScene()
      }
      else {
        label.text = "Tap to Login"
      }
    }.always {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }.error { (error) -> Void in
      label.text = "Tap to Login..."
      DDLogError("RESUME ERR \(error)")
    }
  }

  func pushGameScene() {
    let transition = SKTransition.revealWithDirection(SKTransitionDirection.Down, duration: 1.0)

    let nextScene = GameScene(size: self.scene!.size)
    nextScene.scaleMode = SKSceneScaleMode.AspectFill

    self.scene!.view!.presentScene(nextScene, transition: transition)
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if UIApplication.sharedApplication().networkActivityIndicatorVisible {
      return
    }
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true

    Account.login().then { (playerID) -> Void in
      DDLogInfo("PLAYER ID \(playerID)")
      self.pushGameScene()
    }.always {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }.error { (error) -> Void in
      DDLogError("LOGIN ERR \(error)")
    }
  }

  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
}
