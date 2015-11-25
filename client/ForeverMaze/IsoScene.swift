//
//  IsoScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/25/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import CocoaLumberjack

func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGPoint) -> CGPoint {
  return CGPoint(x: point.x * scalar.x, y: point.y * scalar.y)
}

func / (point: CGPoint, scalar: CGPoint) -> CGPoint {
  return CGPoint(x: point.x / scalar.x, y: point.y / scalar.y)
}

func distance(p1:CGPoint, p2:CGPoint) -> CGFloat {
  return CGFloat(hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y)))
}

func round(point:CGPoint) -> CGPoint {
  return CGPoint(x: round(point.x), y: round(point.y))
}

func floor(point:CGPoint) -> CGPoint {
  return CGPoint(x: floor(point.x), y: floor(point.y))
}

func ceil(point:CGPoint) -> CGPoint {
  return CGPoint(x: ceil(point.x), y: ceil(point.y))
}

class IsoScene: SKScene {

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var mapBox: MapBox
  let viewIso:SKSpriteNode
  let layerIsoGround:SKNode
  let layerIsoObjects:SKNode
  let tileSize = (width:32, height:32)
  var touches = Set<UITouch>()
  var firstTouchLocation = CGPointZero

  init(mapBox: MapBox, size: CGSize) {
    viewIso = SKSpriteNode()
    layerIsoGround = SKNode()
    layerIsoObjects = SKNode()
    self.mapBox = mapBox

    super.init(size: size)
    self.anchorPoint = CGPoint(x:0.5, y:0.5)
  }

  override func didMoveToView(view: SKView) {
    let deviceScale = self.size.width/667

    viewIso.position = CGPoint(x:self.size.width*0, y:self.size.height*0.25)
    viewIso.xScale = deviceScale
    viewIso.yScale = deviceScale
    viewIso.addChild(layerIsoGround)
    viewIso.addChild(layerIsoObjects)
    addChild(viewIso)
  }

  var dPadDirection:Direction? {
    if self.touches.count != 1 || firstTouchLocation.x > self.size.width/2 {
      // We must have exactly one touch that started on the left side of the screen
      return nil
    }
    let touch = self.touches.first!
    let loc = touch.locationInView(self.view)
    let coords = loc - firstTouchLocation
    let degrees = 180 + Int(Float(M_PI_2) - Float(180 / M_PI) * atan2f(Float(coords.x), Float(coords.y)))
    return Direction(degrees: degrees)
  }

  func updateTouches(touches: Set<UITouch>) {
    if self.touches.count <= 0 && touches.count > 0 {
      firstTouchLocation = touches.first!.locationInView(self.view)
    }
    self.touches.unionInPlace(touches)
  }

  func endTouches(touches: Set<UITouch>) {
    self.touches.subtractInPlace(touches)
    firstTouchLocation = CGPointZero
  }

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.updateTouches(touches)
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.endTouches(touches)
  }

  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    self.endTouches(touches!)
  }

  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.updateTouches(touches)
  }

  private func addGameSprite(gameSprite:GameSprite, at: MapPosition, inLayer:SKNode) {
    let position = at - self.mapBox.origin
    gameSprite.sprite.position = point2DToIso(CGPoint(x: (position.xIndex*tileSize.width), y: -(position.yIndex*tileSize.height)))
    gameSprite.sprite.anchorPoint = CGPoint(x:0, y:0)
    inLayer.addChild(gameSprite.sprite)
  }

  func addObject(obj:GameObject) {
    self.addGameSprite(obj, at: obj.position, inLayer: layerIsoObjects)
  }

  func addTile(tile:Tile) {
    self.addGameSprite(tile, at: tile.position, inLayer: layerIsoGround)
  }

  func placeAllTilesIso() {
    fatalError("IsoScene requires placeAllTilesIso to be implemented")
  }

  func point2DToIso(p:CGPoint) -> CGPoint {
    var point = p * CGPoint(x:1, y:-1)
    point = CGPoint(x:(point.x - point.y), y: ((point.x + point.y) / 2))
    point = point * CGPoint(x:1, y:-1)
    return point
  }

  func pointIsoTo2D(p:CGPoint) -> CGPoint {
    var point = p * CGPoint(x:1, y:-1)
    point = CGPoint(x:((2 * point.y + point.x) / 2), y: ((2 * point.y - point.x) / 2))
    point = point * CGPoint(x:1, y:-1)
    return point
  }

  func point2DToPosition(point:CGPoint) -> MapPosition {
    return MapPosition(
      xIndex: Int(point.x / CGFloat(mapBox.size.width)),
      yIndex: Int(point.y / CGFloat(mapBox.size.height))
    )
  }

  func positionToPoint2D(pos:MapPosition) -> CGPoint {
    return CGPoint(x: Int(pos.x * mapBox.size.width), y: Int(pos.y * mapBox.size.height))
  }


  func degreesToDirection(var degrees:CGFloat) -> Direction {
    if (degrees < 0) {
      degrees = degrees + 360
    }
    let directionRange = 45.0
    degrees = degrees + CGFloat(directionRange/2)
    var direction = Int(floor(Double(degrees)/directionRange))

    if (direction == 8) {
      direction = 0
    }
    return Direction(rawValue: direction)!
  }


  func isoOcclusionZSort() {
    let childrenSortedForDepth = layerIsoObjects.children.sort() {
      let p0 = self.pointIsoTo2D($0.position)
      let p1 = self.pointIsoTo2D($1.position)

      if ((p0.x+(-p0.y)) > (p1.x+(-p1.y))) {
        return false
      } else {
        return true
      }
    }
    for i in 0..<childrenSortedForDepth.count {
      let node = (childrenSortedForDepth[i] )
      node.zPosition = CGFloat(i)
    }
  }

  override func update(currentTime: CFTimeInterval) {
    // TODO: determine when a depth sort is needed.
    // IsoGame used a nth-frame timer, which seems silly.
    isoOcclusionZSort()
  }
}
