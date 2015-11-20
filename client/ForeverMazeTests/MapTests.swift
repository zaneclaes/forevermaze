//
//  ForeverMazeTests.swift
//  ForeverMazeTests
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import XCTest
@testable import ForeverMaze

class MapTests : XCTestCase {
  
  static let halfScreenTiles = MapSize(width: Config.screenTiles.width/2, height: Config.screenTiles.height/2)
  
  static let bottomLeftPos = Coordinate(x: 0, y: 0)
  static let topRightPos = Coordinate(x: (Config.worldSize.width - 1), y: (Config.worldSize.width - 1))
  static let centerPos = Coordinate(x: Config.worldSize.width/2, y: Config.worldSize.height/2)
  
  static let centerBox = MapBox(center: centerPos, size: Config.screenTiles)
  static let bottomLeftBox = MapBox(center: bottomLeftPos, size: Config.screenTiles)
  static let topRightBox = MapBox(center: topRightPos, size: Config.screenTiles)
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testMapBoxWrapping() {
    XCTAssert(MapTests.centerBox.wraps == false)
    XCTAssert(MapTests.bottomLeftBox.wraps == true)
    XCTAssert(MapTests.topRightBox.wraps == true)
    
    let xWrapPos = Coordinate(x: Config.worldSize.width - Config.screenTiles.width + 1, y: MapTests.centerPos.y)
    let xWrap = MapBox(origin: xWrapPos, size: Config.screenTiles)
    XCTAssert(xWrap.wraps == true, "\(xWrap) should wrap")
    XCTAssert(xWrap.wrapX == true, "\(xWrap) should wrapX")
    XCTAssert(xWrap.wrapY == false, "\(xWrap) should NOT wrapY")
    
    let xNoWrapPos = Coordinate(x: Config.worldSize.width - Config.screenTiles.width, y: MapTests.centerPos.y)
    let xNoWrap = MapBox(origin: xNoWrapPos, size: Config.screenTiles)
    XCTAssert(xNoWrap.wraps == false, "\(xNoWrap) should NOT wrap")
  }
  
  func testCoordinateIndicies() {
    XCTAssert(MapTests.topRightBox.origin.x == (Config.worldSize.width - MapTests.halfScreenTiles.width - 1))
    XCTAssert(MapTests.topRightBox.origin.xIndex == -1 * Int(MapTests.halfScreenTiles.width + 1))
    XCTAssert(MapTests.topRightBox.origin.y == (Config.worldSize.height - MapTests.halfScreenTiles.height - 1))
    XCTAssert(MapTests.topRightBox.origin.yIndex == -1 * Int(MapTests.halfScreenTiles.height + 1))
    XCTAssert(MapTests.topRightBox.destination.x == MapTests.halfScreenTiles.width-1)
    XCTAssert(MapTests.topRightBox.destination.xIndex == Int(MapTests.halfScreenTiles.width-1))
    XCTAssert(MapTests.topRightBox.destination.y == MapTests.halfScreenTiles.height-1)
    XCTAssert(MapTests.topRightBox.destination.yIndex == Int(MapTests.halfScreenTiles.height-1))
    
    XCTAssert(MapTests.bottomLeftBox.origin.x == (Config.worldSize.width - MapTests.halfScreenTiles.width))
    XCTAssert(MapTests.bottomLeftBox.origin.y == (Config.worldSize.height - MapTests.halfScreenTiles.height))
    XCTAssert(MapTests.bottomLeftBox.destination.x == MapTests.halfScreenTiles.width)
    XCTAssert(MapTests.bottomLeftBox.destination.y == MapTests.halfScreenTiles.height)
  }
  
  func testMapBoxContains() {
    let boxes = [MapTests.centerBox]//, MapTests.bottomLeftBox, MapTests.topRightBox]
    for box in boxes {
      let keyPositions = [box.origin, box.center, box.destination]
      for pos in keyPositions {
        XCTAssert(box.contains(pos), "\(box) should contain \(pos)")
      }
      
      let basePos = Coordinate(xIndex: box.origin.xIndex - 1, yIndex: box.origin.yIndex - 1)
      for var i=0; i<=Int(box.size.width+1); i++ {
        for var j=0; j<=Int(box.size.height+1); j++ {
          let pos = Coordinate(xIndex: basePos.xIndex + i, yIndex: basePos.yIndex + j)
          let outside = i==0 || j==0 || i==Int(box.size.width+1) || j==Int(box.size.width+1)
          XCTAssert(box.contains(pos) != outside, "\(box) should \(outside ? "NOT " : "")contain \(pos)")
        }
      }
    }
  }
  
}
