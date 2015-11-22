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

  let playerID: String!
  dynamic var alias: String?

  init (playerID: String!, snapshot: FDataSnapshot!) {
    self.playerID = playerID
    self.alias = snapshot.childSnapshotForPath("alias").value as? String
    super.init(snapshot: snapshot, attributes: ["alias"])
  }

  override var description:String {
    return "<Player \(playerID)>: \(alias!)"
  }

  var isCurrentUser: Bool {
    return Account.current.isLoggedIn && Account.current.playerID == self.playerID
  }
}
