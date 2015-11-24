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
  dynamic var alias: String!
  dynamic var lastLogin: NSNumber?

  init (playerID: String!, snapshot: FDataSnapshot!) {
    let alias = snapshot.childSnapshotForPath("alias").value as? String
    
    self.playerID = playerID
    self.alias = alias == nil ? "Player" : alias
    self.lastLogin = snapshot.childSnapshotForPath("lastLogin").value as? NSNumber
    super.init(snapshot: snapshot)
  }

  override var description:String {
    return "<\(self.dynamicType) \(playerID)>: \(alias!)"
  }

  var isCurrentUser: Bool {
    return Account.isLoggedIn && Account.playerID == self.playerID
  }
}
