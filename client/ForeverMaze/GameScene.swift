//
//  GameScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright (c) 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import CocoaLumberjack

class GameScene: IsoScene {

  let background:SKSpriteNode = SKSpriteNode(imageNamed: "background")
  let layerUI:GameUILayer
  let layerDialogs:DialogLayer
  let depression:Depression = Depression()
  let gameOverDialog = Dialog(title: I18n.t("dialog.gameOver.title"), body: I18n.t("dialog.gameOver.body"))
  var loaded:Bool = false
  var gameOver:NSTimeInterval = 0
  var nextLevel:NSTimeInterval = 0
  var menuScene:MenuScene?

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(size: CGSize) {
    layerUI = GameUILayer(size: size)
    layerDialogs = DialogLayer(size: size)
    let coord = Account.player?.coordinate
    let center = coord != nil ? coord! : Coordinate(x: 0, y: 0)
    super.init(center: center, worldSize: Config.worldSize, size: size)
    
    background.xScale = max( Config.objectScale, 0.6 )
    background.yScale = max( Config.objectScale, 0.6 )
    background.zPosition = -1000
    
    addChild(background)
    addChild(layerUI)
    addChild(layerDialogs)
  }

  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    Analytics.log(.StartGame)
    guard !loaded && Account.player!.sprite.parent == nil else {
      return
    }

    let label = SKLabelNode(text: I18n.t("menu.loading"))
    label.fontName = Config.headerFont
    label.fontSize = 36
    label.color = SKColor.whiteColor()
    label.position = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    self.addChild(label)

    self.center = (Account.player?.coordinate)!
    Account.player!.draw().then { (player) -> Promise<[String:Player]> in
      return Account.getOtherPlayers(Account.player!.level.numOtherPlayers)
    }.then { (otherPlayers) -> Promise<Void> in
      self.otherPlayers = otherPlayers
      return when(self.loadTiles())
    }.then { (tiles) -> Promise<Void> in
      DDLogInfo("Loaded.")
      
      self.playerSprite = Account.player!.sprite
      self.addObject(Account.player!)
      self.viewIso.position = self.viewIsoPositionForPoint(Account.player!.sprite.position)
      DDLogInfo("Player @ \(Account.player!.sprite.position)")
      
      if Account.player!.depressionCoordinate != nil {
        self.depression.coordinate = Account.player!.depressionCoordinate
      }
      self.layerUI.addTracker(self.depression)
      self.addObject(self.depression)

      Account.player!.unlockTile(self.tiles[Account.player!.coordinate.description]!)
      return Account.player!.setupUnlockedTiles()
    }.then { (players) -> Void in
      Account.player!.updateAdjacentTilesLockedStates()
      self.layerUI.updateUI()
      label.removeFromParent()
    }.always { () -> Void in
      self.loaded = true
    }.error { (error) -> Void in
      label.text = "\(error)"
      DDLogError("World Error \(error)")
    }
  }
  
  var otherPlayers:[String:Player] = [:] {
    didSet {
      for player in otherPlayers.values {
        player.draw().then { (go) -> Void in
          self.addObject(player)
          self.layerUI.addTracker(player)
        }
      }
    }
  }
  
  func prepareNextLevel() {
    Account.player!.reset()
    Account.player!.unlockTile(self.tiles[Account.player!.coordinate.description]!)
    Account.player!.addUnlockedAdjacentCoordinates(Account.player!.coordinate)
    for tile in tiles.values {
      tile.updateLockedState()
    }
    for player in otherPlayers.values {
      player.cleanup()
      self.objects.removeValueForKey(player.id)
    }
    layerUI.updateUI()
    Account.getOtherPlayers(Account.player!.level.numOtherPlayers).then { (otherPlayers) -> Void in
      self.otherPlayers = otherPlayers
    }
  }

  func onGameOver() {
    guard gameOver == 0 else {
      return
    }
    gameOver = NSDate().timeIntervalSince1970
    Analytics.log(.EndGame, params: ["score": Account.player!.score])
    
    Account.player!.score = Account.player!.score + UInt(Account.player!.emoji)
    Account.player!.emoji = 0
    Account.player!.currentLevel = 0
    Account.player!.saveHighScore()
    prepareNextLevel()
    presentDialog(gameOverDialog)
  }
  
  func onBeatLevel(otherPlayer: Player) {
    guard nextLevel == 0 else {
      return
    }
    Analytics.log(.BeatLevel, params: ["level": Account.player!.currentLevel])
    nextLevel = NSDate().timeIntervalSince1970
    Account.player!.currentLevel += 1
    prepareNextLevel()
    
    let body = I18n.t("dialog.nextLevel.body").stringByReplacingOccurrencesOfString("%{name}", withString: otherPlayer.alias!)
    let dialog = Dialog(title: "\(I18n.t("game.level"))\(Account.player!.currentLevel+1)", body: body)
    presentDialog(dialog)
  }
  
  func presentDialog(dialog: Dialog) {
    touches.removeAll()
    layerDialogs.present(dialog)
  }

  func checkEndLevel() -> Bool {
    let dp = Account.player!.depressionCoordinate
    if dp != nil && Account.player!.coordinate == dp && !Config.godMode {
      onGameOver()
      return true
    }
    for player in otherPlayers.values {
      if Account.player!.coordinate == player.coordinate {
        onBeatLevel(player)
        return true
      }
    }
    return false
  }
  
  override func updateTouches(touches: Set<UITouch>) {
    guard layerDialogs.dialogs.count == 0 else {
      return
    }
    super.updateTouches(touches)
  }
  
  private var touchingDialog = false
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard layerDialogs.dialogs.count == 0 else {
      touchingDialog = true
      return
    }
    super.touchesBegan(touches, withEvent: event)
  }
  
  func resetUI() {
    touchingDialog = false
    nextLevel = 0
    gameOver = 0
    while layerDialogs.dismiss() {}
  }
  
  func updateAudioVolumes() {
    var heroVolume:Float = 1
    var depressionVolume:Float = 0
    let depressionCoord = Account.player!.depressionCoordinate
    let depressionDist = depressionCoord == nil ? UInt(UINT32_MAX) : Account.player!.coordinate.getDistance(depressionCoord)
    
    if gameOver > 0 {
      heroVolume = 0
      depressionVolume = 1
    }
    else if nextLevel > 0 {
      // no-op
    }
    else if depressionDist > Config.depressionAudioDistance {
      // no-op
    }
    else {
      // Cross-fade the two audio tracks based upon the distance to Depression
      let cutoffDist:Float = Float(Config.depressionAudioDistance / 2)
      let depressionPercent = (cutoffDist - Float(depressionDist)) / cutoffDist
      let heroPercent = (Float(depressionDist) - cutoffDist) / cutoffDist
      heroVolume = clamp(heroPercent, lower: 0, upper: 1)
      depressionVolume = clamp(depressionPercent, lower: 0, upper: 1)
    }
    
    Audio.sharedInstance.heroTrack.volume = heroVolume
    Audio.sharedInstance.depressionTrack.volume = depressionVolume
  }
  
  override func endTouches(touches: Set<UITouch>) {
    guard gameOver == 0 else {
      let elapsed = NSDate().timeIntervalSince1970 - gameOver
      if elapsed >= 0.5 && touchingDialog {
        resetUI()
        
        let scene = ScoresScene(size: self.size)
        scene.previousScene = self.menuScene!
        scene.scaleMode = SKSceneScaleMode.AspectFill
        self.scene!.view!.presentScene(scene, transition: Config.sceneTransition)
      }
      return
    }
    guard layerDialogs.dialogs.count <= 0 else {
      if layerDialogs.timeSinceLastPresentation >= 0.5 && touchingDialog {
        resetUI()
      }
      return
    }
    touchingDialog = false
    super.endTouches(touches)
  }
  
  override func loadObject(path: String) -> Promise<GameObject!> {
    let existingObject = self.otherPlayers[path]
    guard existingObject == nil else {
      return Promise<GameObject!>(existingObject)
    }
    return super.loadObject(path)
  }
  
  override func shouldLoadObjectID(objId: String) -> Bool {
    return self.otherPlayers[objId] != nil && super.shouldLoadObjectID(objId)
  }

  override func onFacingNewTile() {
    checkEndLevel()
    super.onFacingNewTile()
    layerUI.updateUI()
  }
  
  override func onViewportPanned() {
    super.onViewportPanned()
    layerUI.repositionTrackers()
  }

  override func onObjectFinishedMoving(object: Mobile) {
    if object == self.depression {
      checkEndLevel()
    }
    super.onObjectFinishedMoving(object)
  }

  override func update(currentTime: CFTimeInterval) {
    guard self.loaded && gameOver == 0 else {
      return
    }
    updateAudioVolumes()
    self.depression.hidden = Account.player!.depressionCoordinate == nil    
    if Account.player!.depressionCoordinate != nil && !self.isObjectMoving(self.depression) {
      self.depression.step()
      self.onObjectMoved(self.depression)
    }
    layerUI.repositionTrackers()
    super.update(currentTime)
  }
}
