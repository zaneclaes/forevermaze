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

class MenuScene: InterfaceScene {
  let gameScene = GameScene(size: UIScreen.mainScreen().bounds.size)
  let aboutScene = AboutScene(size: UIScreen.mainScreen().bounds.size)
  let scoresScene = ScoresScene(size: UIScreen.mainScreen().bounds.size)
  
  let labelLoading = SKLabelNode(text: I18n.t("menu.loading"))
  let buttonResume = MenuButton(title: I18n.t("menu.resume"))
  let buttonLogin = MenuButton(title: I18n.t("menu.login"))
  let buttonAbout = MenuButton(title: I18n.t("menu.about"))
  let buttonScores = MenuButton(title: I18n.t("menu.scores"))
  let buttonLogout = MenuButton(title: I18n.t("menu.logout"))
  let player = LocalPlayer(playerID: nil)
  let depression = Depression()
  var tiles = [Tile]()
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    gameScene.menuScene = self
    guard labelLoading.parent == nil else {
      return
    }
    
    let objectZ:CGFloat = 1000
    let mid = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    
    labelLoading.fontName = Config.headerFont
    labelLoading.fontSize = 24
    labelLoading.color = SKColor.whiteColor()
    labelLoading.position = CGPoint(x: mid.x, y: 10)
    self.addChild(labelLoading)
        
    var lastWasX = false
    let playerPosition = CGPoint(x: self.scene!.frame.size.width/5*4, y: self.scene!.frame.size.height/4)
    var coordinate = Coordinate(xIndex: 0,yIndex: 0)
    for(var i=0; i<30; i++) {
      addTile(coordinate, locked: false, center: playerPosition)
      
      // Add random X/Y tiles?
      if arc4random_uniform(2) == 0 {
        addTile(coordinate + (-1,0), locked: true, center: playerPosition)
      }
      if !lastWasX && arc4random_uniform(2) == 0 {
        addTile(coordinate + (1,0), locked: true, center: playerPosition)
      }
      
      if (arc4random_uniform(3) == 0) {
        coordinate = coordinate + (-1,0)
        lastWasX = true
      }
      else {
        coordinate = coordinate + (0,1)
        lastWasX = false
      }
    }
    
    self.player.direction = Direction.S
    player.draw().then { (gameObject) -> Void in
      self.player.sprite.position = playerPosition
      self.player.sprite.zPosition = objectZ
      self.addChild(self.player.sprite)
    }
    
    self.depression.direction = Direction.E
    depression.draw().then { (gameObject) -> Void in
      self.depression.sprite.position = CGPoint(x: self.scene!.frame.size.width/5, y: playerPosition.y)
      self.addChild(self.depression.sprite)
    }
    
    buttonResume.position = mid
    buttonResume.hidden = true
    buttonResume.zPosition = objectZ
    buttonResume.emotion = Emotion.Anger
    buttonResume.buttonFunc = { (button) -> Void in
      self.replaceScene(self.gameScene)
    }
    self.addChild(buttonResume)
    
    buttonLogin.position = buttonResume.position
    buttonLogin.hidden = true
    buttonLogin.zPosition = objectZ
    buttonLogin.emotion = Emotion.Anger
    buttonLogin.buttonFunc = { (button) -> Void in
      self.login()
    }
    self.addChild(buttonLogin)
    
    buttonAbout.stack(buttonLogin)
    buttonAbout.hidden = true
    buttonAbout.zPosition = objectZ
    buttonAbout.emotion = Emotion.Fear
    buttonAbout.buttonFunc = { (button) -> Void in
      self.pushScene(self.aboutScene)
    }
    self.addChild(buttonAbout)
    
    buttonScores.stack(buttonAbout)
    buttonScores.hidden = true
    buttonScores.zPosition = objectZ
    buttonScores.emotion = Emotion.Happiness
    buttonScores.buttonFunc = { (button) -> Void in
      self.pushScene(self.scoresScene)
    }
    self.addChild(buttonScores)
    
    buttonLogout.stack(buttonScores)
    buttonLogout.hidden = true
    buttonLogout.zPosition = objectZ
    buttonLogout.emotion = Emotion.Sadness
    buttonLogout.buttonFunc = { (button) -> Void in
      Account.logout()
      self.updateUI()
    }
    self.addChild(buttonLogout)

    load()
  }
  
  func maybePromptShare() {
    let now = NSDate().timeIntervalSince1970
    let age = now - NSUserDefaults.standardUserDefaults().doubleForKey("lastSharePrompt")
    guard age >= Config.shareDelay && Config.shareRoll > 0 && arc4random_uniform(UInt32(Config.shareRoll)) == 0 else {
      return
    }
    let alert = UIAlertView(
      title: I18n.t("dialog.sharePrompt.title"),
      message: I18n.t("dialog.sharePrompt.body"),
      delegate: nil,
      cancelButtonTitle: I18n.t("menu.cancel"),
      otherButtonTitles: I18n.t("menu.ok")
    )
    alert.promise().then { (button) -> Void in
      guard button != alert.cancelButtonIndex else {
        Analytics.log(.Share, params: ["accept": false])
        return
      }
      Social.shareOnFacebook()
      Analytics.log(.Share, params: ["accept": true])
    }
    NSUserDefaults.standardUserDefaults().setDouble(now, forKey: "lastSharePrompt")
    NSUserDefaults.standardUserDefaults().synchronize()
  }
  
  func addTile(coordinate: Coordinate, locked: Bool, center: CGPoint) -> Tile {
    let tile = Tile(coordinate: coordinate, state: locked ? TileState.Unlockable : TileState.Unlocked)
    tile.sprite.position = gameScene.coordinateToPosition(coordinate, closeToCenter: true) + center - CGPointMake(0, Tile.yOrigin * Config.objectScale)
    tile.sprite.zPosition = gameScene.zPositionForYPosition(tile.sprite.position.y, zIndex: 0)
    tile.loading.then { (obj) -> Void in
      if locked {
        tile.icon.hidden = true
        tile.icon.position = CGPointMake(0, tile.icon.frame.size.height/2 - 8)
      }
    }
    addChild(tile.sprite)
    tiles.append(tile)
    return tile
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

  func login() {
    guard !isLoading else {
      return
    }
    isLoading = true

    Account.login().then { (playerID) -> Void in
      DDLogInfo("PLAYER ID \(playerID)")
      let fader = AudioFader(player: Audio.sharedInstance.depressionTrack)
      fader.fadeOut()
      self.replaceScene(self.gameScene)
    }.always {
      self.isLoading = false
    }.error { (error) -> Void in
      Errors.show(error as NSError)
      DDLogError("LOGIN ERR \(error)")
    }
  }
  
  deinit {
    tiles.removeAll()
  }
}
