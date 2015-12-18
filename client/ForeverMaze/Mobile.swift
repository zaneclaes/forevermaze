//
//  Mobile.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit

class Mobile : GameObject {

  func move(xDist: Int, yDist: Int) {
    self.position = self.position + (xDist, yDist)
  }

  func step(direction: Direction) {
    let (x,y) = direction.amount
    self.move(x, yDist: y)
  }

  func step() {
    self.step(self.direction)
  }
}
