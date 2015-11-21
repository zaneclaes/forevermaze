//
//  GameScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright (c) 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit

class GameScene: SKScene {
  override func didMoveToView(view: SKView) {
    //Map.world.load()

    Account.current.resume().then { (userId) -> Void in
      print("RESUMED: \(userId)")
    }.error { (error) -> Void in
      print("RESUME ERR \(error)")
    }
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if Account.current.isLoggedIn {
      Account.current.logout()
    }
    else {
      Account.current.login().then { (token) -> Void in
        print("TOKEN \(token)")
      }.error { (error) -> Void in
        print("LOGIN ERR \(error)")
      }
    }
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
}
