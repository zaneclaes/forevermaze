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

  /*
  override init(playerID: String) {
    super.init(playerID: playerID)
    self.connection.childByAppendingPath("last_seen").setValue(NSDate().timeIntervalSince1970)
  }*/

  static func load(playerID: String!) -> Promise<LocalPlayer> {
    guard (playerID != nil) else {
      return Promise { fulfill, reject in reject(Error.DoubleOhSux0r) }
    }
    return self.loadFromPath("/players/\(playerID)").then { (snapshot) -> LocalPlayer in
      Account.current.player = LocalPlayer(playerID: playerID, snapshot: snapshot)
      return Account.current.player!
    }
  }

}
