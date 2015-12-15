//
//  LocalPlayer.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import PromiseKit

class LocalPlayer : Player {
  static func loadLocalPlayerID(playerID: String!) -> Promise<LocalPlayer!> {
    guard (playerID != nil) else {
      return Promise { fulfill, reject in fulfill(nil) }
    }
    return Data.loadSnapshot("/players/\(playerID)").then { (snapshot) -> Promise<GameObject!> in
      let player = LocalPlayer(playerID: playerID, snapshot: snapshot)
      Account.player = player
      player.lastLogin = NSDate().timeIntervalSince1970
      GameObject.cache[player.id] = player
      return player.cacheTextures()
    }.then { (gameObject) -> LocalPlayer! in
      return Account.player
    }
  }

}
