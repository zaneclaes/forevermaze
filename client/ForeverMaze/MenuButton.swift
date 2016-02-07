//
//  MenuButton.swift
//  ForeverMaze
//
//  Created by Zane Claes on 1/31/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit

class MenuButton : SgButton {
  
  let icon = SKSpriteNode(texture: Config.worldAtlas.textureNamed("icon_happiness"))
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var emotion:Emotion = Emotion.Happiness {
    didSet {
      icon.texture = Config.worldAtlas.textureNamed("icon_\(emotion.description.lowercaseString)")
      icon.hidden = false
    }
  }
  
  override func containsPoint(p: CGPoint) -> Bool {
    let yPad = CGFloat(20)
    let hitRect = CGRectMake(
      self.frame.origin.x,
      self.frame.origin.y + yPad,
      self.frame.size.width,
      self.frame.size.height - yPad*2
    )
    return CGRectContainsPoint(hitRect, p)
  }

  init(title: String, fontSize: CGFloat = 18, dark: Bool = false) {
    super.init(normalImageNamed: "menu_button", highlightedImageNamed: "menu_button_highlighted", disabledImageNamed: "menu_button_disabled")
    icon.position = CGPointMake(-self.frame.size.width/2 + 44, 0)
    icon.hidden = true
    icon.zPosition = 10000
    self.setString(
      ButtonState.Normal,
      string: title,
      fontName: Config.headerFont,
      fontSize: fontSize,
      stringColor: dark ? .blackColor() : .whiteColor(),
      backgroundColor: .clearColor(),
      size: nil,
      cornerRadius: nil
    )
    self.setString(
      ButtonState.Highlighted,
      string: title,
      fontName: Config.headerFont,
      fontSize: fontSize,
      stringColor: dark ? .grayColor() : .yellowColor(),
      backgroundColor: .clearColor(),
      size: nil,
      cornerRadius: nil
    )
    self.setString(
      ButtonState.Disabled,
      string: title,
      fontName: Config.headerFont,
      fontSize: fontSize,
      stringColor: .grayColor(),
      backgroundColor: .clearColor(),
      size: nil,
      cornerRadius: nil
    )
    addChild(icon)
  }
  
  func stack(otherButton: MenuButton) {
    self.position = CGPoint(x: otherButton.position.x, y: otherButton.position.y - otherButton.frame.size.height + 20)
  }
}
