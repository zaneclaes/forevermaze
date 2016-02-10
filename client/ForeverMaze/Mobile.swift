//
//  Mobile.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit

class Mobile : GameObject {
  dynamic var alias: String! = nil
  
  func move(xDist: Int, yDist: Int) {
    self.coordinate = self.coordinate + (xDist, yDist)
  }

  func step(direction: Direction) {
    let (x,y) = direction.amount
    self.direction = direction
    self.move(x, yDist: y)
  }

  func step() {
    self.step(self.direction)
  }
  
  var trackerTexture:SKTexture {
    return self.sprite.texture!
  }
  
  override func onPropertyChangedRemotely(property: String, oldValue: AnyObject) {
    if property == "x" || property == "y" {
      self.gameScene?.onObjectMoved(self)
    }
    super.onPropertyChangedRemotely(property, oldValue: oldValue)
  }
  
  override var id:String {
    guard self.connection != nil else {
      return "<\(self.dynamicType)>"
    }
    return super.id
  }
}
