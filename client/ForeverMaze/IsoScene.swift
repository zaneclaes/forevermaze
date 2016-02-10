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
  
  static let tileOffset = CGPointMake(0, -Tile.yOrigin * Config.objectScale) // Tiles have a different origin

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let worldSize: MapSize
  let viewIso:SKSpriteNode
  let layerIsoGround:SKNode
  let layerIsoObjects:SKNode
  var onScreenCoordinates = Set<Coordinate>()
  var playerSprite:SKSpriteNode? = nil
  var touches = Set<UITouch>()
  var firstTouchLocation = CGPointZero
  var tiles:[String:Tile] = [:]
  var objects:[String:GameObject] = [:]

  init(center: Coordinate, worldSize: MapSize, size: CGSize) {
    viewIso = SKSpriteNode()
    layerIsoGround = SKNode()
    layerIsoObjects = SKNode()
    self.worldSize = worldSize
    self.center = center

    super.init(size: size)
    self.backgroundColor = UIColor.blackColor()
    self.anchorPoint = CGPoint(x:0.5, y:0.5)
  }

  override func didMoveToView(view: SKView) {
    guard viewIso.parent == nil else {
      return
    }
    let deviceScale = CGFloat(1.0) //self.size.width/667
    let maxPos = coordinateToPosition(Coordinate(x: self.worldSize.width, y: self.worldSize.height))

    viewIso.anchorPoint = CGPointZero
    viewIso.position = self.viewIsoPositionForPoint(coordinateToPosition(self.center))
    viewIso.xScale = deviceScale
    viewIso.yScale = deviceScale
    viewIso.zPosition = 1
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
    if self.touches.count != 1 {
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

  private func addGameSprite(gameSprite:GameStatic, at: Coordinate, inLayer:SKNode, offset: CGPoint) -> Bool {
    guard gameSprite.sprite.parent == nil || gameSprite.sprite.parent == inLayer else {
      return false
    }
    gameSprite.sprite.position = coordinateToPosition(at, closeToCenter: gameSprite.sprite != self.playerSprite) + offset
    gameSprite.sprite.anchorPoint = CGPoint(x:0.5, y:0)
    if gameSprite.sprite.parent != inLayer {
      inLayer.addChild(gameSprite.sprite)
    }
    return true
  }

  func zPositionForYPosition(yPosition: CGFloat, zIndex: CGFloat) -> CGFloat {
    let maxY = self.coordinateToPosition(Coordinate(x: 0, y: self.worldSize.height)).y
    return (CGFloat(1) - (maxY + yPosition) / maxY * 2) + zIndex
  }

  func addObject(obj:GameObject) -> Bool {
    guard self.addGameSprite(obj, at: obj.coordinate, inLayer: layerIsoObjects, offset: CGPointZero) else {
      return false
    }
    self.objects[obj.id] = obj
    obj.sprite.zPosition = self.zPositionForYPosition(obj.sprite.position.y, zIndex: 10)
    obj.onAddedToScene()
    return true
  }
  
  func shouldLoadObjectID(objId: String) -> Bool {
    return !objId.hasSuffix((Account.player?.playerID)!) && objId.rangeOfString("<") == nil
  }
  
  func loadObject(path: String) -> Promise<GameObject!> {
    return Data.loadObject(path)
  }
  
  func loadObjectsInTile(tile: Tile) {
    for path in tile.objectIds {
      if self.objects[path] != nil || !self.shouldLoadObjectID(path) {
        continue
      }
      self.loadObject(path).then { (gameObject) -> Void in
        guard gameObject != nil else {
          DDLogWarn("Failed to load object \(path)")
          return
        }
        self.addObject(gameObject!)
      }
    }
  }

  func addTile(tile:Tile) -> Bool {
    let key = tile.coordinate.description
    guard self.tiles[key] == nil else {
      return false
    }
    if self.addGameSprite(tile, at: tile.coordinate, inLayer: layerIsoGround, offset: IsoScene.tileOffset) {
      tile.sprite.zPosition = self.zPositionForYPosition(tile.sprite.position.y, zIndex: 0)
      self.tiles[tile.coordinate.description] = tile
      self.loadObjectsInTile(tile)
      return true
    }
    else {
      return false
    }
  }

  func removeTile(tile: Tile) -> Void {
    tile.cleanup()
    self.tiles.removeValueForKey(tile.coordinate.description)
  }
  
  static var tileSize:CGSize {
    return CGSizeMake(CGFloat(Tile.size.width) * Config.objectScale, CGFloat(Tile.size.height) * Config.objectScale)
  }

  var center: Coordinate {
    didSet {
      self.onScreenCoordinates.removeAll()
      let area = Int(ceilf(Float(self.size.height + self.size.width) / Float(IsoScene.tileSize.width)))
      let start = self.center - Coordinate(xIndex: area/2, yIndex: area/2)
      for (var xOffset = 0; xOffset < area; xOffset++) {
        for (var yOffset = 0; yOffset < area; yOffset++) {
          let coord = Coordinate(xIndex: start.xIndex + xOffset, yIndex: start.yIndex + yOffset)
          if self.isCoordinateOnScreen(coord, includeBuffer: true) {
            self.onScreenCoordinates.insert(coord)
          }
        }
      }
    }
  }

  /************************************************************************
   * point/position math
   ***********************************************************************/

  func isCoordinateOnScreen(position: Coordinate, includeBuffer: Bool) -> Bool {
    let bufferPx = includeBuffer ? CGFloat(Config.tileBuffer) * IsoScene.tileSize.width : 0
    let maxDist = CGSizeMake(self.size.width / 2 + bufferPx, self.size.height / 2 + bufferPx)
    let testCoord = Coordinate(x: 50, y: 50)
    let offset = position - self.center + testCoord
    let dist = self.coordinateToPosition(offset) - self.coordinateToPosition(testCoord) + CGPoint(x: IsoScene.tileSize.width/2, y: IsoScene.tileSize.height/2)
    return abs(dist.x) < maxDist.width && abs(dist.y) < maxDist.height
  }

  func coordinateToPosition(pos:Coordinate, closeToCenter:Bool = false) -> CGPoint {
    // Since positions can wrap around the world, we choose the point which is closest to our current center.
    var xPos = Int(pos.x)
    var yPos = Int(pos.y)
    if closeToCenter {
      let buffer = UInt(self.size.width / CGFloat(IsoScene.tileSize.width))
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
    
    let pixels = CGPoint(x: CGFloat(xPos) * IsoScene.tileSize.width, y: CGFloat(yPos)*IsoScene.tileSize.height)
    let point = CGPoint(x:((pixels.x + pixels.y)), y: (pixels.y - pixels.x)/2)
    return point
  }
  
  /************************************************************************
   * object moving (remote incoming)
   ***********************************************************************/
  private var objectsMovingTo:[String:CGPoint] = [:]

  func isObjectMoving(object: Mobile) -> Bool {
    return object.sprite.actionForKey(Animation.movementKey) != nil ||
            (self.objectsMovingTo[object.id] != nil && !object.sprite.hidden && self.isCoordinateOnScreen(object.coordinate, includeBuffer: true))
  }

  func onObjectFinishedMoving(object: Mobile) {
    object.sprite.zPosition = self.zPositionForYPosition(object.sprite.position.y, zIndex: 10)
    self.objectsMovingTo.removeValueForKey(object.id)
    object.updateAnimation()
  }

  func animateObjectMovement(object: Mobile) {
    let time = Config.stepTime / object.speed
    let point = coordinateToPosition(object.coordinate, closeToCenter: true)

    let alreadyMovingTo = self.objectsMovingTo[object.id]
    if alreadyMovingTo == nil || alreadyMovingTo! != point {
      object.sprite.removeActionForKey(Animation.movementKey)
      self.objectsMovingTo[object.id] = point
      object.sprite.runAction(SKAction.sequence([
        SKAction.runBlock(object.updateAnimation),
        SKAction.moveTo(point, duration: time),
        SKAction.runBlock({ () -> Void in
          self.onObjectFinishedMoving(object)
        })
      ]), withKey: Animation.movementKey)
    }
  }
  
  func removeObject(object: GameObject) {
    object.cleanup()
    self.objects.removeValueForKey(object.id)
  }

  func onObjectMoved(object: Mobile) {
    guard object != Account.player else {
      // The local player is moved via checkStep()
      return
    }

    if !self.isCoordinateOnScreen(object.coordinate, includeBuffer: true) {
      // Not on screen? Just remove it.
      removeObject(object)
    }
    else if self.objects.keys.contains(object.id) {
      // Moving from one tile to another...
      self.animateObjectMovement(object)
    }
    else {
      // Newly on screen! Just add it.
      addObject(object)
      self.onObjectFinishedMoving(object)
    }
  }

  func onObjectsMoved(objects: Set<Mobile>) {
    for gameObject in objects {
      self.onObjectMoved(gameObject)
    }
  }

  func onObjectsIdsMoved(objectIds: Set<String>) {
    var loadedObjects = Set<Mobile>()
    for objectId in objectIds {
      let gameObject = self.objects[objectId] as? Mobile
      if gameObject != nil {
        loadedObjects.insert(gameObject!)
      }
      else {
        Data.loadObject(objectId).then { (gameObject) -> Void in
          let mobile = self.objects[objectId] as? Mobile
          if mobile != nil {
            self.onObjectMoved(mobile!)
          }
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
  
  // Doing this would get rid of tracked objects
  func unloadOffScreenObjects() {
    for obj in self.objects.values {
      if !self.isCoordinateOnScreen(obj.coordinate, includeBuffer: true) {
        removeObject(obj)
      }
    }
  }
  
  func unloadOffScreenTiles() {
    for tile in self.tiles.values {
      if !self.isCoordinateOnScreen(tile.coordinate, includeBuffer: true) {
        removeTile(tile)
      }
    }
  }

  //
  // Main `loadTiles` function removes anything offscreen, and loads anything onscreen
  //
  var loadingTiles:[String:Promise<Void>] = [:]
  func loadTiles() -> [Promise<Void>] {
    var promises:[Promise<Void>] = []

    // Start by unloading anything off-screen
    self.unloadOffScreenTiles()

    // Then load any new tiles
    for coord in self.onScreenCoordinates {
      let key = coord.description
      if self.tiles[key] != nil {
        continue
      }
      if self.loadingTiles[key] != nil {
        promises.append(self.loadingTiles[key]!)
        continue
      }
      let tile:Tile! = Tile(coordinate: coord, state: TileState.Online)
      let promise = tile.loading.then { (snapshot) -> Void in
        guard snapshot != nil else {
          DDLogWarn("Missing Tile \(key)")
          return
        }
        if !self.isCoordinateOnScreen(tile.coordinate, includeBuffer: true) {
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

  func onFacingNewTile() {
  }
  
  func onViewportPanned() {
  }

  func checkStep() {
    guard playerSprite?.actionForKey(Animation.movementKey) == nil && playerSprite?.actionForKey(Animation.unlockKey) == nil else {
      return
    }
    let dir = self.dPadDirection
    if dir == nil {
      Account.player!.updateAnimation()
      return
    }
    let oldPos = self.center
    let newPos = self.center + dir!.amount
    guard self.tiles[newPos.description] != nil else {
      Account.player!.updateAnimation()
      return
    }
    let tile = self.tiles[newPos.description]!
    var oldPoint = self.coordinateToPosition(oldPos)

    Account.player!.direction = dir!
    if !Account.player!.hasUnlockedTileAt(tile.coordinate) && !Account.player!.canUnlockTile(tile) {
      Account.player!.updateAnimation()
      self.onFacingNewTile()
      return
    }

    Account.player!.step()
    let unlocking = tile.unlockable
    self.center = (Account.player?.coordinate)!
    self.loadTiles()
    
    let point = self.coordinateToPosition(self.center)
    if oldPos.willWrapAroundWorld(self.center, worldSize: self.worldSize, threshold: 1) {
      // Before doing step calculations, teleport around the edge of the world.
      let testCoord = Coordinate(x: 5, y: 5)
      let testPoint = self.coordinateToPosition(testCoord)
      let travelDist = testPoint - self.coordinateToPosition(testCoord + Account.player!.direction.amount)
      let teleportPoint = point + travelDist
      self.playerSprite?.position = teleportPoint
      oldPoint = teleportPoint
      
      // Redraw the world, otherwise we just teleported into nothingness.
      for tile in self.tiles.values {
        tile.sprite.position = coordinateToPosition(tile.coordinate, closeToCenter: true) + IsoScene.tileOffset
        tile.sprite.zPosition = self.zPositionForYPosition(tile.sprite.position.y, zIndex: 0)
      }
      for obj in self.objects.values {
        obj.sprite.position = coordinateToPosition(obj.coordinate, closeToCenter: true)
        obj.sprite.zPosition = self.zPositionForYPosition(obj.sprite.position.y, zIndex: 10)
        
        let mobile = obj as? Mobile
        if mobile != nil && self.isObjectMoving(mobile!) {
          mobile!.sprite.removeActionForKey("move")
          self.objectsMovingTo.removeValueForKey(mobile!.id)
          self.onObjectMoved(mobile!)
        }
      }
    }
    let diff = point - oldPoint
    var first = true
    let time = Config.stepTime / Account.player!.speed
    let moveAction = SKAction.customActionWithDuration(time, actionBlock: { (node, elapsed) -> Void in
      if first {
        Account.player!.updateAnimation()
        first = false
      }
      let percentDone = min(elapsed / CGFloat(time), 1)
      let pos = oldPoint + (diff * CGPoint(x: percentDone, y: percentDone))
      self.playerSprite?.position = pos
      self.viewIso.position = self.viewIsoPositionForPoint(pos)
      self.playerSprite?.zPosition = self.zPositionForYPosition((self.playerSprite?.position.y)!, zIndex: 10)
      self.onViewportPanned()
    })
    
    var actions = [moveAction, SKAction.runBlock(self.onStep)]
    if unlocking {
      actions.append(SKAction.runBlock({ () -> Void in
        Account.player!.updateAnimation(.Idle)
      }))
      actions.append(SKAction.waitForDuration(0.5))
    }
    actions.append(SKAction.runBlock(self.checkStep))
    playerSprite?.runAction(SKAction.sequence(actions), withKey: Animation.movementKey)
  }

  func onStep() {
    let tile = self.tiles[self.center.description]!
    if !Account.player!.unlockTile(tile) {
      Account.player!.updateAnimation()
    }
    self.onFacingNewTile()
  }

  override func update(currentTime: CFTimeInterval) {
    if playerSprite?.actionForKey(Animation.movementKey) == nil && playerSprite?.actionForKey(Animation.unlockKey) == nil {
      self.checkStep()
    }
    super.update(currentTime)
  }
}
