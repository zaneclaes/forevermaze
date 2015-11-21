//
//  GameScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright (c) 2015 inZania LLC. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  override func didMoveToView(view: SKView) {
    Map.world.load()
    Account.current.resume { (error) -> Void in
      print("RESUMED")
    }
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if Account.current.isLoggedIn {
      Account.current.logout()
    }
    else {
      Account.current.login { (error) -> Void in
        print("LOGGED IN YAYYY: \(error)")
      }
    }
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
}
