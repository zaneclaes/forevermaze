//
//  MenuScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/22/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import CocoaLumberjack

class MenuScene: SKScene {
  let background = SKSpriteNode(imageNamed: "background")
  let particle = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("snow", ofType: "sks")!) as! SKEmitterNode
  let labelLoading = SKLabelNode(text: I18n.t("menu.loading"))
  let labelFM = SKLabelNode(text: "ForeverMaze")
  let buttonResume = MenuButton(title: I18n.t("menu.resume"))
  let buttonLogin = MenuButton(title: I18n.t("menu.login"))
  let buttonAbout = MenuButton(title: I18n.t("menu.about"))
  let buttonScores = MenuButton(title: I18n.t("menu.scores"))
  let buttonLogout = MenuButton(title: I18n.t("menu.logout"))
  let player = LocalPlayer(playerID: nil)
  let depression = Depression()
  
  override func didMoveToView(view: SKView) {
    let mid = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    background.position = mid
    background.zPosition = -2
    self.addChild(background)
    
    self.particle.position = CGPointMake(mid.x, CGRectGetMaxY(self.scene!.frame) + 40)
    self.particle.name = "snow"
    self.particle.zPosition = -1
    self.addChild(self.particle)
    
    labelLoading.fontName = Config.font
    labelLoading.fontSize = 24
    labelLoading.color = SKColor.whiteColor()
    labelLoading.position = CGPoint(x: mid.x, y: 10)
    self.addChild(labelLoading)
    
    labelFM.fontName = Config.font
    labelFM.fontSize = 48
    labelFM.color = SKColor.whiteColor()
    labelFM.position = CGPoint(x: mid.x, y: self.scene!.frame.size.height/3*2)
    self.addChild(labelFM)
    
    self.player.direction = Direction.S
    player.draw().then { (gameObject) -> Void in
      self.player.sprite.position = CGPoint(x: self.scene!.frame.size.width/5*4, y: self.scene!.frame.size.height/4)
      self.addChild(self.player.sprite)
    }
    
    self.depression.direction = Direction.E
    depression.draw().then { (gameObject) -> Void in
      self.depression.sprite.position = CGPoint(x: self.scene!.frame.size.width/5, y: self.scene!.frame.size.height/4)
      self.addChild(self.depression.sprite)
    }
    
    buttonResume.position = mid
    buttonResume.hidden = true
    buttonResume.buttonFunc = { (button) -> Void in
      self.pushGameScene()      
    }
    self.addChild(buttonResume)
    
    buttonLogin.position = buttonResume.position
    buttonLogin.hidden = true
    buttonLogin.buttonFunc = { (button) -> Void in
      self.login()
    }
    self.addChild(buttonLogin)
    
    buttonAbout.stack(buttonLogin)
    buttonAbout.hidden = true
    buttonAbout.buttonFunc = { (button) -> Void in
    }
    self.addChild(buttonAbout)
    
    buttonScores.stack(buttonAbout)
    buttonScores.hidden = true
    buttonScores.buttonFunc = { (button) -> Void in
    }
    self.addChild(buttonScores)
    
    buttonLogout.stack(buttonScores)
    buttonLogout.hidden = true
    buttonLogout.buttonFunc = { (button) -> Void in
      Account.logout()
      self.updateUI()
    }
    self.addChild(buttonLogout)

    load()
  }
  
  func load() {
    guard !isLoading && Account.player == nil else {
      updateUI()
      return
    }
    isLoading = true
    DDLogInfo("Loading account...")
    Config.setup().then { () -> Promise<LocalPlayer!> in
      return Account.resume()
    }.then { (player) -> Void in
      DDLogInfo("[PLAYER]: \(player)")
    }.always {
      self.isLoading = false
    }.error { (error) -> Void in
      Errors.show(error as NSError)
      DDLogError("RESUME ERR \(error)")
    }
  }
  
  func updateUI() {
    let canResume = Account.player != nil
    self.buttonLogin.hidden = isLoading || canResume
    self.buttonResume.hidden = isLoading || !canResume
    self.buttonLogout.hidden = self.buttonResume.hidden
    self.buttonAbout.hidden = isLoading
    self.buttonScores.hidden = isLoading
    self.labelLoading.hidden = !isLoading
  }
  
  var isLoading:Bool {
    get {
      return UIApplication.sharedApplication().networkActivityIndicatorVisible
    }
    set {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = newValue
      self.updateUI()
    }
  }

  func pushGameScene() {
    let transition = SKTransition.crossFadeWithDuration(1.5)
    let nextScene = GameScene(size: self.scene!.size)
    nextScene.scaleMode = SKSceneScaleMode.AspectFill
    self.scene!.view!.presentScene(nextScene, transition: transition)
  }

  func login() {
    guard !isLoading else {
      return
    }
    isLoading = true

    Account.login().then { (playerID) -> Void in
      DDLogInfo("PLAYER ID \(playerID)")
      self.pushGameScene()
    }.always {
      self.isLoading = false
    }.error { (error) -> Void in
      Errors.show(error as NSError)
      DDLogError("LOGIN ERR \(error)")
    }
  }
}
