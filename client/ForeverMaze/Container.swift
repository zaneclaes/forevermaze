//
//  Container.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/6/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import SpriteKit

class Container : SKSpriteNode {
  static let tileScale:CGFloat = 0.15
  static let padding = CGFloat(Tile.size.width) * Container.tileScale
  
  let gameScene:GameScene = GameScene(size: UIScreen.mainScreen().bounds.size)
  let background:SKShapeNode
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(minimumSize: CGSize) {
    let tileSize = CGSizeMake(CGFloat(Tile.size.width) * Container.tileScale, CGFloat(Tile.size.height) * Container.tileScale)
    let size = CGSizeMake(CGFloat(ceilf(Float(minimumSize.width / tileSize.width))) * tileSize.width,
                          CGFloat(ceilf(Float(minimumSize.height / tileSize.height))) * tileSize.height)
    background = SKShapeNode(rectOfSize: size)
    gameScene.center = Coordinate(x: 50, y: 50)
    super.init(texture: nil, color: UIColor.clearColor(), size: size)
    
    background.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
    background.zPosition = 0
    addChild(background)
    
    var pos = CGPointZero
    var xDir = true
    var coord = gameScene.center
    let offset = CGPointMake(-size.width/2, -size.height/2)
    while (pos.y) < minimumSize.height/2 {
      let tile = addTile(coord, offset: offset)
      pos = tile.sprite.position
      coord = coord + (xDir ? -1 : 0, xDir ? 0 : 1)
      xDir = !xDir
    }
    
    coord = coord + (1, -1)
    while (pos.x + tileSize.width) < minimumSize.width / 2 {
      let tile = addTile(coord, offset: offset)
      pos = tile.sprite.position
      coord = coord + (xDir ? 1 : 0, xDir ? 0 : 1)
      xDir = !xDir
    }
    
    while pos.y >= offset.y {
      let tile = addTile(coord, offset: offset)
      pos = tile.sprite.position
      coord = coord + (xDir ? 1 : 0, xDir ? 0 : -1)
      xDir = !xDir
    }
    
    coord = coord + (-1, 1)
    while pos.x >= offset.x {
      let tile = addTile(coord, offset: offset)
      pos = tile.sprite.position
      coord = coord + (xDir ? -1 : 0, xDir ? 0 : -1)
      xDir = !xDir
    }
  }
  
  var contentSize:CGSize {
    return CGSizeMake(self.frame.size.width - Container.padding * 2, self.frame.size.height - Container.padding * 2)
  }
  
  func addTile(coordinate: Coordinate, offset: CGPoint) -> Tile {
    let tile = Tile(coordinate: coordinate, state: TileState.Unlocked)
    let pos = gameScene.coordinateToPosition(coordinate, closeToCenter: true) - gameScene.coordinateToPosition(gameScene.center)
    let mult = Container.tileScale / Config.objectScale
    tile.hasDropshadow = true
    tile.scale = Container.tileScale
    tile.sprite.position = CGPointMake(pos.x * mult, pos.y * mult) + offset
    tile.sprite.zPosition = gameScene.zPositionForYPosition(tile.sprite.position.y, zIndex: 100)
    addChild(tile.sprite)
    return tile
  }
}
