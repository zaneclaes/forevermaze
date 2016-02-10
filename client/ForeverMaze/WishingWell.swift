//
//  WishingWell.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/10/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit

class WishingWell : GameObject {
  let particle = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("magic-happiness", ofType: "sks")!) as! SKEmitterNode
  
  init (coord: Coordinate) {
    super.init(firebasePath: nil)
    self.coordinate = coord
  }
  
  override var assetName:String {
    return "wishing_well"
  }
  
  override func onAddedToScene() {
    if self.sprite.scene != nil && self.particle.scene == nil {
      self.particle.position = CGPointMake(0, self.sprite.frame.size.height/2)
      self.particle.name = "magic"
      self.particle.zPosition = 1000
      self.sprite.addChild(self.particle)
    }
    super.onAddedToScene()
  }
}
