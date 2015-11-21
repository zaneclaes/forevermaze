//
//  LocalPlayer.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation

class LocalPlayer : Player {

  override init(playerID: String) {
    super.init(playerID: playerID)
    self.connection.childByAppendingPath("last_seen").setValue(NSDate().timeIntervalSince1970)
  }

}
