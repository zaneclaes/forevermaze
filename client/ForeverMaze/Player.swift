//
//  User.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

class Player : Mobile {

  let playerID: String

  init(playerID: String) {
    self.playerID = playerID
    super.init(connection: Firebase(url: Config.firebaseUrl + "/players/\(playerID)"))
  }

  var isCurrentUser: Bool {
    return Account.current.isLoggedIn && Account.current.playerID == self.playerID
  }
}
