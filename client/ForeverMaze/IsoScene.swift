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

  var center: MapPosition
  let worldSize: MapSize
  let viewIso:SKSpriteNode
  let layerIsoGround:SKNode
  let layerIsoObjects:SKNode
  var playerSprite:SKSpriteNode? = nil
  let tileSize = (width:32, height:32)
  var touches = Set<UITouch>()
  var firstTouchLocation = CGPointZero
  var tiles:[MapPosition:Tile] = [:]

  init(center: MapPosition, worldSize: MapSize, size: CGSize) {
    viewIso = SKSpriteNode()
    layerIsoGround = SKNode()
    layerIsoObjects = SKNode()
    self.worldSize = worldSize
    self.center = center

    super.init(size: size)
    self.anchorPoint = CGPoint(x:0.5, y:0.5)
  }

  override func didMoveToView(view: SKView) {
    let deviceScale = CGFloat(1.0) //self.size.width/667
    let maxPos = mapPositionToIsoPoint(MapPosition(x: self.worldSize.width, y: self.worldSize.height))

    viewIso.anchorPoint = CGPointZero
    viewIso.position = self.viewIsoPositionForPoint(mapPositionToIsoPoint(self.center))
    viewIso.xScale = deviceScale
    viewIso.yScale = deviceScale
    viewIso.addChild(layerIsoGround)
    viewIso.addChild(layerIsoObjects)
    viewIso.anchorPoint = CGPointMake(0.5, 0.5)
    viewIso.size = CGSizeMake(maxPos.x, maxPos.y)
    addChild(viewIso)
  }

  func viewIsoPositionForPoint(p: CGPoint) -> CGPoint {
    return p * CGPointMake(-1, -1)// + CGPointMake(self.size.width/2, self.size.height/2)
  }

  /************************************************************************
   * Touches & Controls
   ***********************************************************************/
  var dPadDirection:Direction? {
    if self.touches.count != 1 || firstTouchLocation.x > self.size.width/2 {
      // We must have exactly one touch that started on the left side of the screen
      return nil
    }
    let touch = self.touches.first!
    let loc = touch.locationInView(self.view)
    if distance(loc, p2: firstTouchLocation) < 10 {
      return nil
    }
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
  /************************************************************************
   * Object Management
   ***********************************************************************/

  private func addGameSprite(gameSprite:GameSprite, at: MapPosition, inLayer:SKNode) {
    gameSprite.sprite.position = mapPositionToIsoPoint(at)
    gameSprite.sprite.anchorPoint = CGPoint(x:0, y:0)
    inLayer.addChild(gameSprite.sprite)
  }

  func addObject(obj:GameObject) {
    self.addGameSprite(obj, at: obj.position, inLayer: layerIsoObjects)
  }

  func addTile(tile:Tile) {
    if self.tiles[tile.position] != nil {
      return
    }
    self.addGameSprite(tile, at: tile.position, inLayer: layerIsoGround)
    self.tiles[tile.position] = tile
  }

  func removeTile(position: MapPosition) -> Tile? {
    let tile = self.tiles[position]
    if tile != nil {
      self.tiles.removeValueForKey(position)
      tile!.sprite.removeFromParent()
    }
    return tile
  }

  /************************************************************************
   * point/position math
   ***********************************************************************/

  func mapPositionToIsoPoint(pos:MapPosition) -> CGPoint {
    let pixels = CGPoint(x: (Int(pos.x)*tileSize.width), y: (Int(pos.y)*tileSize.height))
    let point = CGPoint(x:((pixels.x + pixels.y)), y: (pixels.y - pixels.x)/2)
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
      xIndex: Int(point.x / CGFloat(worldSize.width)),
      yIndex: Int(point.y / CGFloat(worldSize.height))
    )
  }

  func positionToPoint2D(pos:MapPosition) -> CGPoint {
    return CGPoint(x: Int(pos.x * worldSize.width), y: Int(pos.y * worldSize.height))
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
    let baseZ = 5
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
      node.zPosition = CGFloat(i + baseZ)
    }
  }

  /************************************************************************
   * steps / walking
   ***********************************************************************/

  func drawTiles() {
    let boundingBox:MapBox = MapBox(center: self.center, size: Config.screenTiles)
    for i in 0..<Int(boundingBox.size.width) {
      for j in 0..<Int(boundingBox.size.height) {
        let position = boundingBox.origin + (i,j)
        if Map.tiles.contains(position) {
          addTile(Map.tiles[position])
        }
      }
    }
    for tile in self.tiles.values {
      if !boundingBox.contains(tile.position) {
        removeTile(tile.position)
      }
    }
    self.isoOcclusionZSort()
  }

  private func onMoved() {
    let qualityOfServiceClass = QOS_CLASS_BACKGROUND
    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
    dispatch_async(backgroundQueue, {
      Map.load(Account.player!.position).then { () -> Void in
        dispatch_async(dispatch_get_main_queue(), self.drawTiles)
      }
    })
  }

  private func checkStep() {
    let dir = self.dPadDirection
    if dir == nil {
      return
    }
    let oldPos = self.center
    var oldPoint = self.mapPositionToIsoPoint(oldPos)

    Account.player!.direction = dir!
    Account.player!.step()
    self.center = (Account.player?.position)!
    self.onMoved()
    
    let point = self.mapPositionToIsoPoint(self.center)
    let wrapX = (self.center.x == 0 && oldPos.x == self.worldSize.width - 1) ||
                (self.center.x == self.worldSize.width - 1 && oldPos.x == 0)
    let wrapY = (self.center.y == 0 && oldPos.y == self.worldSize.height - 1) ||
                (self.center.y == self.worldSize.height - 1 && oldPos.y == 0)
    if wrapX || wrapY {
      // Before doing step calculations, teleport around the edge of the world.
      let testPos = MapPosition(x: 5, y: 5)
      let testPoint = self.mapPositionToIsoPoint(testPos)
      let travelDist = testPoint - self.mapPositionToIsoPoint(testPos + Account.player!.direction.amount)
      let teleportPoint = point + travelDist
      self.playerSprite?.position = teleportPoint
      oldPoint = teleportPoint
    }
    let diff = point - oldPoint
    let dist = Double(distance((playerSprite?.position)!, p2: point))
    let time = dist * Config.stepTime

    let moveAction = SKAction.customActionWithDuration(time, actionBlock: { (node, elapsed) -> Void in
      let percentDone = min(elapsed / CGFloat(time), 1)
      let pos = oldPoint + (diff * CGPoint(x: percentDone, y: percentDone))
      self.playerSprite?.position = pos
      self.viewIso.position = self.viewIsoPositionForPoint(pos)
    })

    playerSprite?.runAction(SKAction.sequence([
      moveAction,
      SKAction.runBlock(self.checkStep)
    ]), withKey: "step")
  }

  override func update(currentTime: CFTimeInterval) {
    if playerSprite?.actionForKey("step") == nil {
      self.checkStep()
    }
    super.update(currentTime)
  }
}
