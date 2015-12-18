//
//  IsoScene.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/25/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import CocoaLumberjack
import PromiseKit

class IsoScene: SKScene {

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let worldSize: MapSize
  let viewIso:SKSpriteNode
  let layerIsoGround:SKNode
  let layerIsoObjects:SKNode
  var onScreenPositions = Set<MapPosition>()
  var playerSprite:SKSpriteNode? = nil
  let tileSize = (width:32, height:32)
  var touches = Set<UITouch>()
  var firstTouchLocation = CGPointZero
  var tiles:[String:Tile] = [:]
  var objects:[String:GameObject] = [:]

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
    //return Direction.N
    if self.touches.count != 1 || firstTouchLocation.x > self.size.width/2 {
      // We must have exactly one touch that started on the left side of the screen
      return nil
    }
    let touch = self.touches.first!
    let loc = touch.locationInView(self.view)
    if distance(loc, p2: firstTouchLocation) < 3 {
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

  private func addGameSprite(gameSprite:GameSprite, at: MapPosition, inLayer:SKNode) -> Bool {
    guard gameSprite.sprite.parent == nil || gameSprite.sprite.parent == inLayer else {
      return false
    }
    gameSprite.sprite.position = mapPositionToIsoPoint(at, closeToCenter: gameSprite.sprite != self.playerSprite)
    gameSprite.sprite.anchorPoint = CGPoint(x:0, y:0)
    if gameSprite.sprite.parent != inLayer {
      inLayer.addChild(gameSprite.sprite)
    }
    self.isoOcclusionZSort()
    return true
  }

  func addObject(obj:GameObject) -> Bool {
    guard self.addGameSprite(obj, at: obj.position, inLayer: layerIsoObjects) else {
      return false
    }
    self.objects[obj.id] = obj;
    return true;
  }

  func addTile(tile:Tile) -> Bool {
    let key = tile.position.description
    guard self.tiles[key] == nil else {
      return false
    }
    if self.addGameSprite(tile, at: tile.position, inLayer: layerIsoGround) {
      self.tiles[tile.position.description] = tile
      for objId in tile.objectIds {
        if self.objects[objId] != nil || objId.hasSuffix((Account.player?.playerID)!) {
          continue
        }
        Data.loadObject(objId).then { (gameObject) -> Void in
          guard gameObject != nil else {
            DDLogWarn("Failed to load object \(objId)")
            return
          }
          self.addObject(gameObject!)
        }
      }
      return true
    }
    else {
      return false
    }
  }

  func removeTile(tile: Tile) -> Void {
    tile.cleanup()
    self.tiles.removeValueForKey(tile.position.description)
  }

  var center: MapPosition {
    didSet {
      self.onScreenPositions.removeAll()
      let area = Int(ceilf(Float(self.size.height + self.size.width) / Float(self.tileSize.width)))
      let start = self.center - MapPosition(xIndex: area/2, yIndex: area/2)
      for (var xOffset = 0; xOffset < area; xOffset++) {
        for (var yOffset = 0; yOffset < area; yOffset++) {
          let pos = MapPosition(xIndex: start.xIndex + xOffset, yIndex: start.yIndex + yOffset)
          if self.isPositionOnScreen(pos) {
            self.onScreenPositions.insert(pos)
          }
        }
      }
    }
  }

  /************************************************************************
   * point/position math
   ***********************************************************************/

  func isPositionOnScreen(position: MapPosition) -> Bool {
    let bufferPx = CGFloat(Config.tileBuffer * tileSize.width)
    let maxDist = CGSizeMake(self.size.width / 2 + bufferPx, self.size.height / 2 + bufferPx)
    let testPos = MapPosition(x: 50, y: 50)
    let offset = position - self.center + testPos
    let dist = self.mapPositionToIsoPoint(offset) - self.mapPositionToIsoPoint(testPos) + CGPoint(x: tileSize.width/2, y: tileSize.height/2)
    return abs(dist.x) < maxDist.width && abs(dist.y) < maxDist.height
  }

  func mapPositionToIsoPoint(pos:MapPosition, closeToCenter:Bool) -> CGPoint {
    // Since positions can wrap around the world, we choose the point which is closest to our current center.
    var xPos = Int(pos.x)
    var yPos = Int(pos.y)
    if closeToCenter {
      let buffer = UInt(self.size.width / CGFloat(self.tileSize.width))
      if self.center.x >= (self.worldSize.width - buffer) && pos.x < buffer {
        xPos += Int(self.worldSize.width)
      }
      else if self.center.x <= buffer && pos.x >= (self.worldSize.width - buffer) {
        xPos = pos.xIndex
      }
      if self.center.y >= (self.worldSize.height - buffer) && pos.y < buffer {
        yPos += Int(self.worldSize.height)
      }
      else if self.center.y <= buffer && pos.y >= (self.worldSize.height - buffer) {
        yPos = pos.yIndex
      }
    }
    
    let pixels = CGPoint(x: xPos * tileSize.width, y: yPos*tileSize.height)
    let point = CGPoint(x:((pixels.x + pixels.y)), y: (pixels.y - pixels.x)/2)
    return point
  }
  
  func mapPositionToIsoPoint(pos:MapPosition) -> CGPoint {
    return self.mapPositionToIsoPoint(pos, closeToCenter: false)
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
   * object moving (remote incoming)
   ***********************************************************************/

  private var objectsMovingTo:[String:CGPoint] = [:]
  func animateObjectMovement(object: GameObject) {
    let animationKey = "move"
    let time = object.movememntTime
    let point = mapPositionToIsoPoint(object.position, closeToCenter: true)

    let alreadyMovingTo = self.objectsMovingTo[object.id]
    if alreadyMovingTo == nil || alreadyMovingTo! != point {
      object.sprite.removeActionForKey(animationKey)
      self.objectsMovingTo[object.id] = point
      object.sprite.runAction(SKAction.sequence([
        SKAction.moveTo(point, duration: time),
        SKAction.runBlock({ () -> Void in
          self.isoOcclusionZSort()
          self.objectsMovingTo.removeValueForKey(object.id)
        })
      ]), withKey: animationKey)
    }
  }

  func onObjectMoved(object: GameObject) {
    guard object != Account.player else {
      // The local player is moved via checkStep()
      return
    }

    if !self.isPositionOnScreen(object.position) {
      // Not on screen? Just remove it.
      object.cleanup()
      self.objects.removeValueForKey(object.id)
    }
    else if self.objects.keys.contains(object.id) {
      // Moving from one tile to another...
      self.animateObjectMovement(object)
    }
    else {
      // Newly on screen! Just add it.
      addObject(object);
    }
  }

  func onObjectsMoved(objects: Set<GameObject>) {
    for gameObject in objects {
      self.onObjectMoved(gameObject)
    }
  }

  func onObjectsIdsMoved(objectIds: Set<String>) {
    var loadedObjects = Set<GameObject>()
    for objectId in objectIds {
      let gameObject = self.objects[objectId]
      if gameObject != nil {
        loadedObjects.insert(gameObject!)
      }
      else {
        Data.loadObject(objectId).then { (gameObject) -> Void in
          self.onObjectMoved(gameObject)
        }
      }
    }

    // First, do a quick-pass on the loaded objects
    // Even though loadObjects skips double-loads, if we had a mixed-set,
    // we'd be waiting on all objects to load before moving the existing objects.
    self.onObjectsMoved(loadedObjects)
  }

  /************************************************************************
   * steps / walking
   ***********************************************************************/

  //
  // Main `loadTiles` function removes anything offscreen, and loads anything onscreen
  //
  var loadingTiles:[String:Promise<Void>] = [:]
  func loadTiles() -> [Promise<Void>] {
    var promises:[Promise<Void>] = []

    // Start by unloading anything off-screen
    for tile in self.tiles.values {
      if !self.isPositionOnScreen(tile.position) {
        removeTile(tile)
      }
    }
    for obj in self.objects.values {
      if !self.isPositionOnScreen(obj.position) {
        obj.cleanup()
        self.objects.removeValueForKey(obj.id)
      }
    }

    // Then load any new tiles
    for pos in self.onScreenPositions {
      let key = pos.description
      if self.tiles[key] != nil {
        continue
      }
      if self.loadingTiles[key] != nil {
        promises.append(self.loadingTiles[key]!)
        continue
      }
      var tile:Tile! = nil
      let promise = Data.loadSnapshot("/tiles/\(key)").then { (snapshot) -> Void in
        guard snapshot != nil else {
          DDLogWarn("Missing Tile \(key)")
          return
        }
        tile = Tile(position: pos, snapshot: snapshot!)
        if !self.isPositionOnScreen(tile.position) {
          self.removeTile(tile)
        }
        else if tile.sprite.parent == nil {
          self.addTile(tile)
        }
        self.loadingTiles.removeValueForKey(key)!
      }
      promises.append(promise)
      loadingTiles[key] = promise
    }
    return promises
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
    self.loadTiles()
    
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
      
      // Redraw the world, otherwise we just teleported into nothingness.
      for tile in self.tiles.values {
        tile.sprite.position = mapPositionToIsoPoint(tile.position, closeToCenter: true)
      }
      for obj in self.objects.values {
        obj.sprite.position = mapPositionToIsoPoint(obj.position, closeToCenter: true)
      }
      self.isoOcclusionZSort()
    }
    let diff = point - oldPoint
    let moveAction = SKAction.customActionWithDuration(Account.player!.movememntTime, actionBlock: { (node, elapsed) -> Void in
      let percentDone = min(elapsed / CGFloat(Account.player!.movememntTime), 1)
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
