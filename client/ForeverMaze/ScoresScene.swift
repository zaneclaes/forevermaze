//
//  ScoresScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import CocoaLumberjack
import PromiseKit

enum PlayerGroup : Int {
  case AllPlayers, Friends
}

class ScoresScene: InterfaceScene {
  
  let container = Container(minimumSize: CGSizeMake(UIScreen.mainScreen().bounds.width * 4/5, UIScreen.mainScreen().bounds.height * 3/5))
  let buttonAllPlayers = MenuButton(title: I18n.t("menu.allPlayers"))
  let buttonFriends = MenuButton(title: I18n.t("menu.friends"))
  let labelLoading = SKLabelNode(text: I18n.t("menu.loading"))
  let labelEmpty = SKLabelNode(text: I18n.t("menu.nobody"))
  var players:[PlayerGroup:[Player]] = [:]
  var scoreNodes:[ScoreNode] = []
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    guard labelLoading.parent == nil else {
      return
    }
    
    labelTitle.text = I18n.t("menu.scores")
    
    container.position = CGPointMake(self.size.width/2, labelTitle.position.y - container.frame.size.height/2 + 6)
    addChild(container)
    container.runAction(SKAction.fadeInWithDuration(0.25))
    
    labelLoading.fontName = Config.headerFont
    labelLoading.fontSize = 24
    labelLoading.position = container.position
    labelLoading.fontColor = .blackColor()
    labelLoading.hidden = true
    addChild(labelLoading)
    
    labelEmpty.fontName = Config.headerFont
    labelEmpty.fontSize = 24
    labelEmpty.position = container.position
    labelEmpty.fontColor = .blackColor()
    labelEmpty.hidden = true
    addChild(labelEmpty)
    
    buttonAllPlayers.position = CGPoint(x: CGRectGetMinX(container.frame) + buttonAllPlayers.frame.size.width/2 - 36, y: buttonBack.position.y)
    buttonAllPlayers.emotion = Emotion.Fear
    buttonAllPlayers.buttonFunc = { (button) -> Void in
      self.playerGroup = .AllPlayers
    }
    addChild(buttonAllPlayers)
    
    buttonFriends.position = CGPoint(x: CGRectGetMaxX(buttonAllPlayers.frame) + 100, y: buttonBack.position.y)
    buttonFriends.emotion = Emotion.Happiness
    buttonFriends.buttonFunc = { (button) -> Void in
      self.playerGroup = .Friends
    }
    addChild(buttonFriends)
    
    playerGroup = Account.facebookFriends.count > 0 ? .Friends : .AllPlayers
  }
  
  override func popScene() {
    super.popScene()
    if self.previousScene is MenuScene {
      let menu = self.previousScene as! MenuScene
      menu.maybePromptShare()
    }
  }
  
  var playerGroup:PlayerGroup = .AllPlayers {
    didSet {
      self.buttonAllPlayers.disabled = true
      self.buttonFriends.disabled = true
      self.labelEmpty.hidden = true
      
      while scoreNodes.count > 0 {
        scoreNodes.removeFirst().removeFromParent()
      }
      
      loadPlayerGroup(playerGroup).then { (players) -> Void in
        self.buttonAllPlayers.disabled = self.playerGroup == .AllPlayers
        self.buttonFriends.disabled = self.playerGroup == .Friends
        self.drawPlayerScores(players)
      }
    }
  }
  
  /**
   * Render scores for an array of players on-screen
   */
  func drawPlayerScores(players:[Player]) {
    guard players.count > 0 else {
      labelEmpty.hidden = false
      return
    }
    labelEmpty.hidden = true
    let startY = CGRectGetMaxY(container.frame) - Container.padding - 20
    var pos = CGPointMake(CGRectGetMinX(container.frame) + Container.padding + 20, startY)
    for player in players {
      let nodeScore = ScoreNode(player: player)
      nodeScore.position = pos + CGPointMake(nodeScore.frame.size.width/2, -nodeScore.frame.size.height/2)
      addChild(nodeScore)
      scoreNodes.append(nodeScore)
      
      pos.y -= (nodeScore.frame.size.height + 40)
      if pos.y <= (CGRectGetMinY(container.frame) + Container.padding + nodeScore.frame.size.height/2) {
        pos.y = startY
        pos.x += nodeScore.frame.size.width + 20
        if pos.x >= CGRectGetMaxX(container.frame) - Container.padding - nodeScore.frame.size.width/2 {
          break
        }
      }
    }
  }
  
  /**
   * Ensure that the appropriate player group is populated
   */
  func loadPlayerGroup(playerGroup:PlayerGroup) -> Promise<[Player]> {
    var promise:Promise<[Player]>? = nil
    if playerGroup == .Friends {
      promise = Account.loadFriends()
    }
    else if playerGroup == .AllPlayers {
      promise = Account.loadHighScorers()
    }
    guard promise != nil else {
      return Promise<[Player]>([])
    }
    labelLoading.hidden = false
    return promise!.then { (players) -> [Player] in
      self.players[playerGroup] = players
      self.labelLoading.hidden = true
      return players
    }
  }
}
