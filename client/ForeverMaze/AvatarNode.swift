//
//  AvatarNode.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit

class AvatarNode : SKSpriteNode {
  static let diameter:CGFloat = 100
  static let padding:CGFloat = 4
  static let stroke:CGFloat = 2
  static let pointer:CGFloat = 20
  
  let background:SKShapeNode = SKShapeNode(circleOfRadius: Tracker.diameter/2) // Empty circle BK
  let mask = SKShapeNode(circleOfRadius: AvatarNode.diameter/2 - AvatarNode.padding)
  var picture:SKCropNode = SKCropNode() // Crops the unmasked picture into a circle
  let circle:SKShapeNode = SKShapeNode(circleOfRadius: Tracker.diameter/2 - Tracker.padding)// Masking creates aliasing. This masks the aliasing.
  
  private var unmaskedPicture:SKSpriteNode!
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init() {
    let pictureSize = CGSizeMake(AvatarNode.diameter, AvatarNode.diameter)
    super.init(texture: nil, color: UIColor.clearColor(), size: pictureSize)
    
    self.xScale = Config.objectScale
    self.yScale = Config.objectScale
    
    background.strokeColor = .blackColor()
    background.lineWidth = AvatarNode.stroke
    background.fillColor = .whiteColor()
    self.addChild(background)
    
    mask.lineWidth = 0
    mask.fillColor = .whiteColor()
    picture.maskNode = mask
    self.addChild(picture)
    
    circle.strokeColor = .blackColor()
    circle.lineWidth = AvatarNode.stroke
    circle.fillColor = .clearColor()
    self.addChild(circle)
  }
  
  func loadPlayerPicture(player: Player) {
    self.pictureTexture = player.animation!.getTexture(.Idle, direction: .S)
    let scale:CGFloat = UIScreen.mainScreen().scale
    let size = CGSizeMake(mask.frame.size.width * scale, mask.frame.size.height * scale)
    player.getProfilePicture(size).then { (image) -> Void in
      let rescaled = UIImage(CGImage: image.CGImage!, scale: scale, orientation: image.imageOrientation)
      self.pictureTexture = SKTexture(image: rescaled)
    }
  }
  
  /**
   * Assigning this automatically crops the texture and replaces it in the circle
   */
  var pictureTexture:SKTexture {
    set {
      if unmaskedPicture != nil {
        unmaskedPicture.removeFromParent()
      }
      unmaskedPicture = SKSpriteNode(texture: newValue)
      picture.addChild(unmaskedPicture)
    }
    get {
      return unmaskedPicture.texture!
    }
  }
}
