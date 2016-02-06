//
//  AboutScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import CocoaLumberjack
import PromiseKit

class AboutScene: InterfaceScene {
  
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    labelTitle.text = I18n.t("menu.about")
  }
}
