//
//  GameSprite.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

class GameSprite {
  let connection: Firebase!

  convenience init (path: String!) {
    self.init(connection: Firebase(url: Config.firebaseUrl + path))
  }

  init (connection: Firebase!) {
    self.connection = connection
    /*self.connection.observeEventType(.Value, withBlock: {
      snapshot in
      print("[DATA] \(snapshot.key) -> \(snapshot.value)")
    })*/
  }
}
