//
//  DialogLayer.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import CocoaLumberjack

class DialogLayer : SKSpriteNode {
  static let animationTime:NSTimeInterval = 0.25
  
  let background:SKShapeNode
  var dialogs = [Dialog]()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(size: CGSize) {
    // Ugly hack for creating an initial size
    // http://stackoverflow.com/questions/21837172/how-to-subclass-an-sknode-to-initialize-it-with-a-predetermined-size
    background = SKShapeNode(rectOfSize: size)
    super.init(texture: nil, color: UIColor.clearColor(), size: size)
    
    background.fillColor = .blackColor()
    background.alpha = 0
    background.zPosition = 1020
    addChild(background)
  }
  
  func present(dialog: Dialog) {
    if self.dialogs.count == 0 {
      background.runAction(SKAction.fadeAlphaTo(0.66, duration: DialogLayer.animationTime))
    }
    dialog.xScale = 0
    dialog.yScale = 0
    dialog.runAction(SKAction.scaleTo(1, duration: DialogLayer.animationTime))
    addChild(dialog)
    dialogs.append(dialog)
    dialog.presentedAt = NSDate().timeIntervalSince1970
    dialog.zPosition = background.zPosition + CGFloat(dialogs.count)
  }
  
  func dismiss() -> Bool {
    guard dialogs.count > 0 else {
      return false
    }
    if self.dialogs.count == 1 {
      background.runAction(SKAction.fadeOutWithDuration(DialogLayer.animationTime))
    }
    let dialog = dialogs.first!
    dialog.runAction(SKAction.sequence([
      SKAction.scaleTo(0, duration: DialogLayer.animationTime),
      SKAction.runBlock({ () -> Void in
        dialog.removeFromParent()
      })
    ]))
    self.dialogs.removeAtIndex(0)
    return true
  }
  
  var timeSinceLastPresentation:NSTimeInterval {
    let now = NSDate().timeIntervalSince1970
    guard self.dialogs.count > 0 else {
      return now
    }
    let dialog = self.dialogs.last!
    return now - dialog.presentedAt
  }
}
