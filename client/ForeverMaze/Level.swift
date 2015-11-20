//
//  Level.swift
//  ForeverMaze
//
//  Created by Zane Claes on 1/12/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

class Level {
  let levelNumber:UInt
  let depressionSpeedMultiplier:Double
  let depressionSpawnDistance:Int
  let depressionSpawnAfterTiles:Int
  let numOtherPlayers:Int

  init(snapshot: FDataSnapshot!, number: UInt) {
    self.levelNumber = number
    self.depressionSpeedMultiplier = snapshot.childSnapshotForPath("depressionSpeedMultiplier").value as! Double
    self.depressionSpawnDistance = snapshot.childSnapshotForPath("depressionSpawnDistance").value as! Int
    self.depressionSpawnAfterTiles = snapshot.childSnapshotForPath("depressionSpawnAfterTiles").value as! Int
    self.numOtherPlayers = snapshot.childSnapshotForPath("numOtherPlayers").value as! Int
  }
}
