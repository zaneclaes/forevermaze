//
//  InterfaceScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import CocoaLumberjack
import PromiseKit
import AVFoundation

class InterfaceScene: SKScene {
  
  let background = SKSpriteNode(imageNamed: "background")
  let banner = SKSpriteNode(texture: Config.worldAtlas.textureNamed("banner"))
  let labelTitle = SKLabelNode(text: "ForeverMaze")
  let particle = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("snow", ofType: "sks")!) as! SKEmitterNode
  let buttonBack = MenuButton(title: I18n.t("menu.back"))
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    Audio.sharedInstance.fadeToTrack(musicTrack)
    Analytics.view("\(self.dynamicType)")
    guard background.parent == nil else {
      return
    }
    
    let mid = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    background.position = mid
    background.xScale = max( Config.objectScale, 0.6 )
    background.yScale = max( Config.objectScale, 0.6 )
    background.zPosition = -2
    addChild(background)
    
    particle.position = CGPointMake(mid.x, CGRectGetMaxY(self.scene!.frame) + 40)
    particle.name = "snow"
    particle.zPosition = -1
    addChild(particle)
    
    banner.position = CGPoint(x: mid.x, y: self.scene!.frame.size.height/4*3)
    banner.zPosition = 1001
    addChild(banner)
    
    labelTitle.fontName = Config.headerFont
    labelTitle.fontSize = 28
    labelTitle.color = SKColor.whiteColor()
    labelTitle.position = banner.position + CGPointMake(0, 0)
    labelTitle.zPosition = 1002
    addChild(labelTitle)
    
    buttonBack.position = mid
    buttonBack.hidden = self.previousScene == nil
    buttonBack.zPosition = 1000
    buttonBack.position = CGPointMake(
      scene!.frame.size.width - buttonBack.frame.size.width / 2 + 10,
      scene!.frame.size.height - buttonBack.frame.size.height/2
    )
    buttonBack.emotion = Emotion.Sadness
    buttonBack.buttonFunc = { (button) -> Void in
      self.popScene()
    }
    addChild(buttonBack)
  }
  
  var musicTrack:AVAudioPlayer {
    return Audio.sharedInstance.depressionTrack
  }
  
  var previousScene:InterfaceScene? {
    didSet {
      self.buttonBack.hidden = self.previousScene == nil
    }
  }
  
  func replaceScene(scene: SKScene) {
    scene.scaleMode = SKSceneScaleMode.AspectFill
    self.scene!.view!.presentScene(scene, transition: Config.sceneTransition)
  }
  
  func pushScene(scene: InterfaceScene) {
    scene.scaleMode = SKSceneScaleMode.AspectFill
    scene.previousScene = self
    self.scene!.view!.presentScene(scene, transition: Config.sceneTransition)
  }
  
  func popScene() {
    guard self.previousScene != nil else {
      return
    }
    let scene = self.previousScene!
    scene.scaleMode = SKSceneScaleMode.AspectFill
    self.scene!.view!.presentScene(scene, transition: Config.sceneTransition)
  }
}
