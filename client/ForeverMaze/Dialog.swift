//
//  Dialog.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit

class Dialog : SKSpriteNode {
  static let width = 600 * Config.objectScale
  
  let banner = SKSpriteNode(texture: Config.worldAtlas.textureNamed("banner"))
  let labelTitle = SKLabelNode(fontNamed: Config.headerFont)
  let labelBody:SKMultilineLabel
  let container:Container
  var presentedAt:NSTimeInterval = 0
  
  init(title: String, body: String) {
    labelBody = SKMultilineLabel(
      text: body,
      labelWidth: Int(Dialog.width - Container.padding*2),
      pos: CGPointZero,
      fontName: Config.bodyFont,
      fontSize: 14,
      fontColor: .blackColor(),
      leading: 14,
      alignment: .Center,
      shouldShowBorder: false
    )
    let contentHeight = CGFloat(max(labelBody.labelHeight, 80))
    let size = CGSizeMake(CGFloat(Dialog.width), contentHeight + Container.padding * 2)
    container = Container(minimumSize: size)
    labelBody.position = CGPointMake(0, container.frame.size.height/2 - Container.padding - 40)
    
    banner.position = CGPointMake(0, size.height/2)
    banner.zPosition = 1010
    banner.xScale = 0.66
    banner.yScale = 0.66
    
    labelTitle.zPosition = 1011
    labelTitle.color = .whiteColor()
    labelTitle.text = title
    labelTitle.fontSize = 18
    labelTitle.position = banner.position
    
    super.init(texture: nil, color: UIColor.clearColor(), size: size)
    
    addChild(container)
    addChild(banner)
    addChild(labelTitle)
    addChild(labelBody)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
}
