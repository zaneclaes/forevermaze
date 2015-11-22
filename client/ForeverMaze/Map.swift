//
//  Map.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

class Map {
  static let world = Map()
  static let connection: Firebase! = Firebase(url: Config.firebaseUrl + "/tiles")

  var tiles = Array<Array<Tile>>()

  func load() {
    Map.connection.observeEventType(.Value, withBlock: { (snapshot) -> Void in
      var x:UInt = 0
      for column in snapshot.children.allObjects as! [FDataSnapshot] {
        var columnBuilder = Array<Tile>()
        var y:UInt = 0
        for row in column.children.allObjects as! [FDataSnapshot] {
          columnBuilder.append(Tile(x: x, y: y, snapshot: row))
          y++
        }
        x++
        self.tiles.append(columnBuilder)
      }
      // snapshot.childrenCount, snapshot.children
    })
  }
}
