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
  static let diameter:CGFloat = 80
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
    
    mobile.addObserver(self, forKeyPath: "x", options: [.New, .Old], context: &KVOContext)
    mobile.addObserver(self, forKeyPath: "y", options: [.New, .Old], context: &KVOContext)

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
    let vector = mobile.gameScene!.coordinateToPosition(mobile.coordinate) - mobile.gameScene!.coordinateToPosition(Account.player!.coordinate)
    let slope = vector.x==0 ? 1 : vector.y / vector.x
    let pad = Int(Tracker.diameter * 2/3)
    let xRange = NSMakeRange(pad, Int(mobile.gameScene!.size.width) - pad)
    let yRange = NSMakeRange(pad, Int(mobile.gameScene!.size.height) - pad - Int(Tracker.bubble))
    var point = CGPointMake(mobile.gameScene!.size.width/2, mobile.gameScene!.size.height/2)
    while (Int(point.x) >= xRange.location) && (Int(point.x) <= xRange.length) && (Int(point.y) >= yRange.location) && (Int(point.y) <= yRange.length) {
      point.x += vector.x > 0 ? 1 : (vector.x < 0 ? -1 : 0)
      point.y += vector.x < 0 ? -slope : slope
    }
    self.moveTo(point)
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
  
  deinit {
    mobile.sprite.removeObserver(self, forKeyPath: "x")
    mobile.sprite.removeObserver(self, forKeyPath: "y")
  }
}
