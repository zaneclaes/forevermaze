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
  dynamic var alias: String! = nil
  dynamic var lastLogin: NSNumber? = nil

  init (playerID: String!, snapshot: FDataSnapshot!) {
    self.playerID = playerID
    super.init(snapshot: snapshot)
    self.alias = self.alias == nil ? "Player" : self.alias
  }

  override var guardedProperties:[String] {
    return super.guardedProperties + ["alias"]
  }

  override var description:String {
    return "<\(self.dynamicType) \(playerID)>: \(alias == nil ? "" : alias!) @\(self.position)->\(self.direction)"
  }

  override var id:String {
    return "/players/\(self.playerID)"
  }

  var isCurrentUser: Bool {
    return Account.isLoggedIn && Account.playerID == self.playerID
  }
}
