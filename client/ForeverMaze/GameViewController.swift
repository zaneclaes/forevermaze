//
//  GameViewController.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright (c) 2015 inZania LLC. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  
  let menuScene = MenuScene(size: UIScreen.mainScreen().bounds.size)

  override func viewDidLoad() {
    super.viewDidLoad()
    skView.showsFPS = Config.debug
    skView.showsNodeCount = Config.debug
    skView.ignoresSiblingOrder = true
    showMenu()
  }
  
  func showMenu() {
    guard skView.scene == nil || !skView.scene!.isKindOfClass(MenuScene) else {
      return
    }
    menuScene.scaleMode = .ResizeFill
    skView.presentScene(menuScene)
  }
  
  var skView:SKView {
    return view as! SKView
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Landscape
  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
}
