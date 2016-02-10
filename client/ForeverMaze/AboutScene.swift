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
  
  let container = Container(minimumSize: CGSizeMake(UIScreen.mainScreen().bounds.width * 4/5, UIScreen.mainScreen().bounds.height * 3/5))
  let buttonWebsite = MenuButton(title: "Forever\nMaze.com", fontSize: 12, dark: true)
  let buttonShare = MenuButton(title: I18n.t("menu.share"), fontSize: 12, dark: true)
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    guard container.parent == nil else {
      return
    }
    
    labelTitle.text = I18n.t("menu.about")
    
    container.position = CGPointMake(self.size.width/2, labelTitle.position.y - container.frame.size.height/2 + 4)
    addChild(container)
    container.runAction(SKAction.fadeInWithDuration(0.25))
    
    let aboutText = "ForeverMaze is a game of battling depression by building bridges to your friends. Created by Zane Claes (inZania LLC)."
    let label = SKMultilineLabel(
      text: aboutText,
      labelWidth: Int(container.frame.size.width - Container.padding*2),
      pos: CGPointMake(self.size.width/2, CGRectGetMaxY(container.frame) - Container.padding - 40),
      fontName: Config.bodyFont,
      fontSize: 14,
      fontColor: .blackColor(),
      leading: 14,
      alignment: .Center,
      shouldShowBorder: false
    )
    addChild(label)
    
    buttonWebsite.position = CGPoint(
      x: self.frame.size.width/2 - buttonWebsite.frame.size.width/2,
      y: CGRectGetMinY(container.frame) + Container.padding + 40
    )
    buttonWebsite.emotion = Emotion.Anger
    buttonWebsite.buttonFunc = { (button) -> Void in
      UIApplication.sharedApplication().openURL(NSURL(string: "http://ForeverMaze.com")!)
    }
    addChild(buttonWebsite)
    
    buttonShare.position = CGPoint(
      x: self.frame.size.width/2 + buttonWebsite.frame.size.width/2,
      y: CGRectGetMinY(container.frame) + Container.padding + 40
    )
    buttonShare.emotion = Emotion.Happiness
    buttonShare.buttonFunc = { (button) -> Void in
      Social.shareOnFacebook()
    }
    addChild(buttonShare)
  }
}
