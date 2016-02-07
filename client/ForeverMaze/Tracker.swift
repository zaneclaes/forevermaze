//
//  Tracker.swift
//  ForeverMaze
//
//  Created by Zane Claes on 1/19/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import CocoaLumberjack

private var KVOContext = 1

class Tracker : AvatarNode {
  let mobile:Mobile

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(mobile: Mobile) {
    self.mobile = mobile
    super.init()

    if mobile is Player {
      self.loadPlayerPicture(mobile as! Player)
    }
    else {
      self.pictureTexture = mobile.animation!.getTexture(.Idle, direction: .S)
      background.fillColor = UIColor(red: 0.24, green: 0.2, blue: 0.36, alpha: 1)
    }

    reposition()
  }
  
  /**
   * Re-calculate and assign the visibility & position
   */
  func reposition() {
    guard !mobile.sprite.hidden && mobile.gameScene != nil else {
      self.hidden = true
      return
    }
    guard !mobile.isOnScreen else {
      if mobile is Depression {
        self.hidden = true
      }
      else {
        let pos = mobile.gameScene!.convertPoint(mobile.sprite.position, fromNode: mobile.gameScene!.layerIsoObjects)
        let offset = CGPointMake(0, mobile.sprite.frame.size.height + Tracker.diameter/2 * Config.objectScale)
        let center = CGPointMake(mobile.gameScene!.size.width/2, mobile.gameScene!.size.height/2)
        self.hidden = false
        self.position = pos + center + offset
      }
      return
    }
    // Convert coordinates to space so that we ignore changes in Z position (i.e., jumping)
    let targetPosition = mobile.gameScene!.coordinateToPosition(mobile.coordinate)
    let playerPosition = mobile.gameScene!.coordinateToPosition(Account.player!.coordinate)
    
    // We want to know where the vector, projected from the player position on the screen, intersects with the screen bounds
    // c.f., http://math.stackexchange.com/questions/625266/find-collision-point-between-vector-and-fencing-rectangle
    let vector = targetPosition - playerPosition
    let pad = CGFloat(AvatarNode.diameter * 2/3 * Config.objectScale)
    let theta:Float = atan2f(Float(vector.y), Float(vector.x))
    let a = CGFloat(cosf(theta))
    let b = CGFloat(sinf(theta))
    let viewSize = CGSizeMake((mobile.gameScene!.size.width - CGFloat(pad * 2)), (mobile.gameScene!.size.height - CGFloat(pad * 2)))
    let origin = CGPointMake(viewSize.width/2, viewSize.height/2)
    let tValues:[CGFloat] = [
      (viewSize.width - origin.x) / a,
      (viewSize.height - origin.y) / b,
      -origin.x / a,
      -origin.y / b
    ]
    var t:CGFloat = -1
    for tValue in tValues {
      if tValue >= 0 && (t < 0 || tValue < t) {
        t = tValue
      }
    }
    if t >= 0 {
      self.hidden = false
      self.position = CGPoint(x: origin.x + t * a, y: origin.y + t * b) + CGPointMake(pad, pad)
    }
  }
}
