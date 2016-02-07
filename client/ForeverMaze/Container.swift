//
//  Container.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit

class Container : SKSpriteNode {
  static let tileScale:CGFloat = 0.3 * Config.objectScale
  static let padding = CGFloat(Tile.size.width) * Container.tileScale * 1.5
  
  let testScene:IsoScene = IsoScene(center: Coordinate(x: 50, y: 50), worldSize: Config.worldSize, size: UIScreen.mainScreen().bounds.size)
  let background:SKShapeNode
  var tiles = [Tile]()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(minimumSize: CGSize) {
    let tileSize = CGSizeMake(CGFloat(Tile.size.width) * Container.tileScale, CGFloat(Tile.size.height) * Container.tileScale)
    let size = CGSizeMake(CGFloat(ceilf(Float(minimumSize.width / tileSize.width))) * tileSize.width,
                          CGFloat(ceilf(Float(minimumSize.height / tileSize.height))) * tileSize.height)
    background = SKShapeNode(rectOfSize: size)
    super.init(texture: nil, color: UIColor.clearColor(), size: size)
    
    background.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
    background.zPosition = 0
    addChild(background)
    
    var pos = CGPointZero
    var xDir = true
    var coord = testScene.center
    let offset = CGPointMake(-size.width/2, -size.height/2)
    
    let build = SKAction.runBlock { () -> Void in
      while (pos.y) < minimumSize.height/2 {
        let tile = self.addTile(coord, offset: offset)
        pos = tile.sprite.position
        coord = coord + (xDir ? -1 : 0, xDir ? 0 : 1)
        xDir = !xDir
      }
      coord = coord + (1, -1)
      while (pos.x + tileSize.width) < minimumSize.width / 2 {
        let tile = self.addTile(coord, offset: offset)
        pos = tile.sprite.position
        coord = coord + (xDir ? 1 : 0, xDir ? 0 : 1)
        xDir = !xDir
      }
      while pos.y >= offset.y {
        let tile = self.addTile(coord, offset: offset)
        pos = tile.sprite.position
        coord = coord + (xDir ? 1 : 0, xDir ? 0 : -1)
        xDir = !xDir
      }
      coord = coord + (-1, 1)
      while pos.x >= offset.x {
        let tile = self.addTile(coord, offset: offset)
        pos = tile.sprite.position
        coord = coord + (xDir ? -1 : 0, xDir ? 0 : -1)
        xDir = !xDir
      }
    }
    runAction(build)
  }
  
  var contentSize:CGSize {
    return CGSizeMake(self.frame.size.width - Container.padding * 2, self.frame.size.height - Container.padding * 2)
  }
  
  func addTile(coordinate: Coordinate, offset: CGPoint) -> Tile {
    let tile = Tile(coordinate: coordinate, state: TileState.Unlocked)
    let pos = testScene.coordinateToPosition(coordinate, closeToCenter: true) - testScene.coordinateToPosition(testScene.center)
    let mult = Container.tileScale / Config.objectScale
    tile.hasDropshadow = true
    tile.scale = Container.tileScale
    tile.sprite.position = CGPointMake(pos.x * mult, pos.y * mult) + offset
    tile.sprite.zPosition = testScene.zPositionForYPosition(tile.sprite.position.y, zIndex: 100)
    addChild(tile.sprite)
    tiles.append(tile)
    return tile
  }
  
  deinit {
    tiles.removeAll()
  }
}
