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

class Tracker : SKNode {
  static let diameter:CGFloat = 100
  static let padding:CGFloat = 4
  static let stroke:CGFloat = 2
  static let pointer:CGFloat = 20
  static let bubble:CGFloat = 12

  let mobile:Mobile
  let background:SKShapeNode = SKShapeNode(circleOfRadius: Tracker.diameter/2) // Empty circle BK
  let bubbleName = SKShapeNode(rectOfSize: CGSizeMake(Tracker.diameter, Tracker.bubble))
  let labelName = SKLabelNode(fontNamed: "AvenirNext")
  var picture:SKCropNode = SKCropNode() // Crops the unmasked picture into a circle
  let circle:SKShapeNode = SKShapeNode(circleOfRadius: Tracker.diameter/2 - Tracker.padding)// Masking creates aliasing. This masks the aliasing.

  private var unmaskedPicture:SKSpriteNode!

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(mobile: Mobile) {
    self.mobile = mobile
    super.init()
    
    self.xScale = Config.objectScale
    self.yScale = Config.objectScale
    
    background.strokeColor = .blackColor()
    background.lineWidth = Tracker.stroke
    background.fillColor = .whiteColor()
    self.addChild(background)

    let mask = SKShapeNode(circleOfRadius: Tracker.diameter/2 - Tracker.padding)
    mask.lineWidth = 0
    mask.fillColor = .whiteColor()
    picture.maskNode = mask
    if mobile is Player {
      self.texture = Account.player!.sprite.texture!
      let scale:CGFloat = UIScreen.mainScreen().scale
      let size = CGSizeMake(mask.frame.size.width * scale, mask.frame.size.height * scale)
      let player = mobile as! Player
      player.getProfilePicture(size).then { (image) -> Void in
        let rescaled = UIImage(CGImage: image.CGImage!, scale: scale, orientation: image.imageOrientation)
        self.texture = SKTexture(image: rescaled)
      }
    }
    else {
      self.texture = mobile.sprite.texture!
      unmaskedPicture.xScale = 0.5
      unmaskedPicture.yScale = 0.5
      background.fillColor = UIColor(red: 0.24, green: 0.2, blue: 0.36, alpha: 1)
    }
    self.addChild(picture)
    
    circle.strokeColor = .blackColor()
    circle.lineWidth = Tracker.stroke
    circle.fillColor = .clearColor()
    self.addChild(circle)
    
    bubbleName.fillColor = .whiteColor()
    bubbleName.strokeColor = .blackColor()
    bubbleName.lineWidth = Tracker.stroke
    bubbleName.position = CGPointMake(0, Tracker.diameter/2 + Tracker.stroke)
    //addChild(bubbleName)
    
    labelName.text = mobile.alias
    labelName.fontColor = .blackColor()
    labelName.fontSize = 11
    labelName.position = CGPointMake(0, -5)
    //bubbleName.addChild(labelName)

    reposition()
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    reposition()
  }
  
  func moveTo(point: CGPoint) {
    self.hidden = false
    self.position = point
  }

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
        let offset = CGPointMake(0, mobile.sprite.frame.size.height + Tracker.diameter/2)
        let center = CGPointMake(mobile.gameScene!.size.width/2, mobile.gameScene!.size.height/2)
        self.moveTo(pos + center + offset)
      }
      return
    }
    // Convert coordinates to space so that we ignore changes in Z position (i.e., jumping)
    let targetPosition = mobile.gameScene!.coordinateToPosition(mobile.coordinate)
    let playerPosition = mobile.gameScene!.coordinateToPosition(Account.player!.coordinate)
    
    // We want to know where the vector, projected from the player position on the screen, intersects with the screen bounds
    // c.f., http://math.stackexchange.com/questions/625266/find-collision-point-between-vector-and-fencing-rectangle
    let vector = targetPosition - playerPosition
    let pad = CGFloat(Tracker.diameter * 2/3 * Config.objectScale)
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
      let p = CGPoint(x: origin.x + t * a, y: origin.y + t * b) + CGPointMake(pad, pad)
      moveTo(p)
    }
  }

  /**
   * Assigning this automatically crops the texture and replaces it in the circle
   */
  var texture:SKTexture {
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
