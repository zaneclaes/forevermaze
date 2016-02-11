//
//  GameUILayer.swift
//  ForeverMaze
//
//  Created by Zane Claes on 1/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import CocoaLumberjack

class GameUILayer : SKSpriteNode {
  let uiZ:CGFloat = 2000
  let buttonChangeTile = SgButton(
    normalTexture: Config.worldAtlas.textureNamed("button_up"),
    highlightedTexture: Config.worldAtlas.textureNamed("button_down")
  )
  let buttonPotion = SgButton(
    normalTexture: Config.worldAtlas.textureNamed("potion_happiness")
  )
  let labelPotion = SKLabelNode(text: "0")
  let banner = SKSpriteNode(texture: Config.worldAtlas.textureNamed("banner"))
  let labelBanner = SKLabelNode(text: "😀 x 0")
  var trackers = Array<Tracker>()

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(size: CGSize) {
    // Ugly hack for creating an initial size
    // http://stackoverflow.com/questions/21837172/how-to-subclass-an-sknode-to-initialize-it-with-a-predetermined-size
    super.init(texture: nil, color: UIColor.clearColor(), size: size)
    self.position = CGPointMake(-size.width/2, -size.height/2)
    self.zPosition = uiZ

    let sidePad:CGFloat = 10

    buttonChangeTile.anchorPoint = CGPointMake(1, 0)
    buttonChangeTile.position = CGPointMake(size.width - sidePad, sidePad)
    buttonChangeTile.zPosition = uiZ + 10
    buttonChangeTile.buttonFunc = { (button) -> Void in
      let facing = Account.player!.coordinate + Account.player!.direction.amount
      let tile = self.gameScene.tiles[facing.description]
      guard Account.player!.emoji >= Config.flipTileCost && tile != nil else {
        self.updateUI()
        return
      }
      let emotions = Emotion.emotions.shuffle()
      for e in emotions {
        if Account.player!.canUnlockEmotion(e) {
          tile!.emotion = e
          tile!.playUnlockAnimation()
          break
        }
      }
      Account.player!.emoji -= Config.flipTileCost
      self.updateUI()
      
      let label = SKLabelNode(text: "😀")
      label.fontName = Config.headerFont
      label.fontSize = 36
      label.position = self.labelBanner.position - CGPointMake(0, 40)
      self.addChild(label)
      
      let move = SKAction.moveTo(CGPointMake(self.frame.size.width/2, self.frame.size.height/2 + 80), duration: 1)
      let remove = SKAction.runBlock(label.removeFromParent)
      label.runAction(SKAction.sequence([move, remove]))
      
      label.runAction(SKAction.fadeAlphaTo(0, duration: 0.75))
    }
    self.addChild(buttonChangeTile)
    
    buttonPotion.anchorPoint = CGPointMake(1,1)
    buttonPotion.position = CGPointMake(size.width - sidePad, size.height - sidePad)
    buttonPotion.buttonFunc = { (button) -> Void in
      Account.player!.numHappinessPotions -= 1
      Account.player!.happinessPotionTimeRemaining = Config.happinessPotionDuration
      self.updateUI()
      self.buttonPotion.runAction(MenuButton.sound)
    }
    buttonPotion.zPosition = uiZ + 10
    addChild(buttonPotion)
    
    labelPotion.fontName = Config.headerFont
    labelPotion.fontColor = .whiteColor()
    labelPotion.fontSize = 14
    labelPotion.zPosition = buttonPotion.zPosition + 1
    labelPotion.position = CGPointMake(CGRectGetMidX(buttonPotion.frame), CGRectGetMidY(buttonPotion.frame) - 8)
    addChild(labelPotion)
    
    banner.position = CGPoint(x: size.width/2, y: size.height - sidePad - labelBanner.frame.size.height/2)
    banner.zPosition = 1
    banner.xScale = 0.66
    banner.yScale = banner.xScale
    addChild(banner)

    labelBanner.color = .whiteColor()
    labelBanner.fontName = Config.headerFont
    labelBanner.fontSize = 14
    labelBanner.zPosition = 2
    labelBanner.position = banner.position + CGPointMake(0, 1)
    self.addChild(labelBanner)
    
    updateUI()
  }

  func addTracker(mobile: Mobile) {
    let tracker = Tracker(mobile: mobile)
    tracker.position = CGPoint(x: CGRectGetMidX(self.scene!.frame) + CGFloat(arc4random_uniform(300)),
                               y: CGRectGetMidY(self.scene!.frame) + CGFloat(arc4random_uniform(300)))
    self.addChild(tracker)
    trackers.append(tracker)
  }

  var gameScene:GameScene {
    return self.scene as! GameScene
  }
  
  func repositionTrackers() {
    for tracker in trackers {
      tracker.reposition()
    }
  }

  func updateUI() {
    let facing = Account.player!.coordinate + Account.player!.direction.amount
    let tile = self.gameScene.tiles[facing.description]
    buttonChangeTile.hidden = tile == nil || tile!.unlocked || tile!.unlockable || Account.player!.emoji < Config.flipTileCost
    labelBanner.text = "\(I18n.t("game.level"))\(Account.player!.currentLevel+1) 😀 x\(Account.player!.emoji)"
    buttonPotion.hidden = Account.player!.happinessPotionTimeRemaining <= 0 && Account.player!.numHappinessPotions <= 0
    labelPotion.hidden = buttonPotion.hidden
    if Account.player!.happinessPotionTimeRemaining > 0 {
      buttonPotion.disabled = true
      labelPotion.text = "\(Int(Account.player!.happinessPotionTimeRemaining))"
      labelPotion.fontColor = .blackColor()
    }
    else {
      buttonPotion.disabled = false
      labelPotion.text = "\(Account.player!.numHappinessPotions)"
      labelPotion.fontColor = .whiteColor()
    }
    repositionTrackers()
  }

  func runEmojiAnimation(emotion: Emotion) {
    let label = SKLabelNode(text: emotion.emoji)
    label.fontName = Config.headerFont
    label.fontSize = 36
    label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2 + 80)
    self.addChild(label)

    let move = SKAction.moveTo(CGPointMake(label.position.x, labelBanner.position.y), duration: 1)
    let remove = SKAction.runBlock(label.removeFromParent)
    label.runAction(SKAction.sequence([move, remove]))

    label.runAction(SKAction.fadeAlphaTo(0, duration: 0.75))
  }
}
