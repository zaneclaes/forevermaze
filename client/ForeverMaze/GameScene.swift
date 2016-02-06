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
  let depression:Depression = Depression()
  var loaded:Bool = false

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(size: CGSize) {
    layerUI = GameUILayer(size: size)
    let coord = Account.player?.coordinate
    let center = coord != nil ? coord! : Coordinate(x: 0, y: 0)
    super.init(center: center, worldSize: Config.worldSize, size: size)
    
    background.xScale = max( Config.objectScale, 0.6 )
    background.yScale = max( Config.objectScale, 0.6 )
    background.zPosition = -1000
    
    addChild(background)
    addChild(layerUI)
  }

  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    guard !loaded && Account.player!.sprite.parent == nil else {
      return
    }

    let label = SKLabelNode(text: I18n.t("menu.loading"))
    label.fontName = Config.font
    label.fontSize = 36
    label.color = SKColor.whiteColor()
    label.position = CGPoint(x: CGRectGetMidX(self.scene!.frame), y: CGRectGetMidY(self.scene!.frame))
    self.addChild(label)

    self.center = (Account.player?.coordinate)!
    Account.getOtherPlayers(Account.player!.level.numOtherPlayers).then { (otherPlayers) -> Promise<Void> in
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
    Account.player!.depressionPos = ""
    Account.player!.emoji = 0
    Account.player!.numAnger = 0
    Account.player!.numSadness = 0
    Account.player!.numHappiness = 0
    Account.player!.numFear = 0
    Account.player!.unlockedTiles = Array<String>()
    Account.player!.adjacentPositions = [:]
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
    Account.player!.currentLevel = 0
    prepareNextLevel()
  }
  
  func onBeatLevel() {
    Account.player!.currentLevel += 1
    prepareNextLevel()
  }

  func checkEndLevel() -> Bool {
    let dp = Account.player!.depressionCoordinate
    if dp != nil && Account.player!.coordinate == dp && !Config.godMode {
      onGameOver()
      return true
    }
    for player in otherPlayers.values {
      if Account.player!.coordinate == player.coordinate {
        onBeatLevel()
        return true
      }
    }
    return false
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
    guard self.loaded else {
      return
    }
    self.depression.sprite.hidden = Account.player!.depressionCoordinate == nil
    if Account.player!.depressionCoordinate != nil && !self.isObjectMoving(self.depression) {
      self.depression.step()
      self.onObjectMoved(self.depression)
    }
    layerUI.repositionTrackers()
    super.update(currentTime)
  }
}
