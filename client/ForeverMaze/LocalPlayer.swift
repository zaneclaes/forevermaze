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
    return Data.loadSnapshot("/players/\(playerID)").then { (snapshot) -> LocalPlayer in
      Account.player = LocalPlayer(playerID: playerID, snapshot: snapshot)
      Account.player?.lastLogin = NSDate().timeIntervalSince1970
      return Account.player!
    }
  }

}
