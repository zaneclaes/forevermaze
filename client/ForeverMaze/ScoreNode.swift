//
//  ScoreNode.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit

class ScoreNode : AvatarNode {
  
  let player:Player
  let labelName = SKLabelNode(fontNamed: Config.headerFont)
  let labelScore = SKLabelNode(fontNamed: Config.headerFont)
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(player: Player) {
    self.player = player
    super.init()
    
    loadPlayerPicture(player)
    
    labelName.text = player.alias
    labelName.fontColor = .blackColor()
    labelName.fontSize = 11
    labelName.xScale = 1 / self.xScale
    labelName.yScale = 1 / self.yScale
    labelName.position = CGPointMake(0, CGRectGetMinY(background.frame) - 18)
    addChild(labelName)
    
    labelScore.text = "😀x\(String.Count(player.highScore))"
    labelScore.fontColor = .blackColor()
    labelScore.fontSize = 11
    labelScore.xScale = 1 / self.xScale
    labelScore.yScale = 1 / self.yScale
    labelScore.position = CGPointMake(0, labelName.position.y - 14 * 1/Config.objectScale)
    addChild(labelScore)

  }
}
