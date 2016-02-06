//
//  AboutScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import CocoaLumberjack
import PromiseKit

class AboutScene: InterfaceScene {
  
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    labelTitle.text = I18n.t("menu.about")
    
    let size = CGSizeMake(400, 200)
    let frame = Container(minimumSize: size)
    frame.position = CGPointMake(self.size.width/2, labelTitle.position.y - size.height/2 + 4)
    addChild(frame)
    
    let aboutText = "ForeverMaze is a game of battling depression by building bridges to your friends. Created by Zane Claes (inZania LLC)."
    let label = SKMultilineLabel(
      text: aboutText,
      labelWidth: Int(size.width - Container.padding*2),
      pos: CGPointMake(self.size.width/2, self.size.height/2 + frame.frame.size.height/2 - Container.padding - 40),
      fontName: Config.font,
      fontSize: 14,
      fontColor: .blackColor(),
      leading: 14,
      alignment: .Center,
      shouldShowBorder: false
    )
    addChild(label)
    
  }
}
