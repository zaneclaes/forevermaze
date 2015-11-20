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
  let uiZ:CGFloat = 1000
  let buttonChangeTile = SgButton(normalTexture: Config.worldAtlas.textureNamed("button_up"), highlightedTexture: Config.worldAtlas.textureNamed("button_down"))
  let labelEmoji = SKLabelNode(text: "😀 x 0")
  let labelLevel = SKLabelNode(fontNamed: Config.font)
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
          break
        }
      }
      Account.player!.emoji -= Config.flipTileCost
      self.updateUI()
    }
    self.addChild(buttonChangeTile)

    labelEmoji.color = SKColor.whiteColor()
    labelEmoji.fontName = Config.font
    labelEmoji.fontSize = 24
    labelEmoji.zPosition = 1
    labelEmoji.position = CGPoint(x: size.width/2, y: size.height - sidePad - labelEmoji.frame.size.height)
    self.addChild(labelEmoji)
    
    labelLevel.color = .whiteColor()
    labelLevel.fontSize = 24
    labelLevel.zPosition = 1
    labelLevel.position = CGPointMake(size.width - 50, labelEmoji.position.y)
    addChild(labelLevel)
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
    labelEmoji.text = "😀 x \(Account.player!.emoji)"
    labelLevel.text = "\(I18n.t("game.level"))\(Account.player!.currentLevel+1)"
    repositionTrackers()
  }

  func runEmojiAnimation(emotion: Emotion) {
    let label = SKLabelNode(text: emotion.emoji)
    label.fontName = Config.font
    label.fontSize = 36
    label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2 + 80)
    self.addChild(label)

    let move = SKAction.moveTo(CGPointMake(label.position.x, labelEmoji.position.y), duration: 1)
    let remove = SKAction.runBlock(label.removeFromParent)
    label.runAction(SKAction.sequence([move, remove]))

    label.runAction(SKAction.fadeAlphaTo(0, duration: 0.75))
  }
}
