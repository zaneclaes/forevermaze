//
//  GameOverScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/10/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import CocoaLumberjack
import PromiseKit

class GameOverScene: InterfaceScene {
  
  var highScore:Bool = false
  var stepsToFriend:Int = 0
  let labelDistance = SKLabelNode(fontNamed: Config.headerFont)
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    labelTitle.text = highScore ? I18n.t("dialog.highScore.title") : I18n.t("dialog.gameOver.title")
    labelDistance.text = I18n.t("dialog.gameOver.body").stringByReplacingOccurrencesOfString("%{steps}", withString: String(stepsToFriend))
    
    guard labelDistance.parent == nil else {
      return
    }
    
    labelDistance.fontSize = 12
    labelDistance.color = SKColor.whiteColor()
    labelDistance.position = CGPoint(x: CGRectGetMidX(self.frame), y: 10)
    self.addChild(labelDistance)
   
  }
}
