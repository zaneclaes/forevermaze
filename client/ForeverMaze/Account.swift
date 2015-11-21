//
//  Account.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase

class Account {
  static let current: Account = Account()
  private static let fb: FBSDKLoginManager = FBSDKLoginManager()

  var player: Player?
  private var auth: FAuthData? = nil
  private let connection: Firebase

  init() {
    self.connection = Firebase(url: Config.firebaseUrl)
  }

  func resume(completion: ((error: NSError!) -> Void)!) {
    guard let token: FBSDKAccessToken = FBSDKAccessToken.currentAccessToken() else {
      completion?(error: nil)
      return
    }
    self._loginWithToken(token, completion: completion)
  }

  func login(completion: ((error: NSError!) -> Void)!) {
    guard let token: FBSDKAccessToken = FBSDKAccessToken.currentAccessToken() else {
      print("[LOGIN] Facebook start...")
      let permissions : Array<String> = ["public_profile", "email", "user_friends"]
      Account.fb.logInWithReadPermissions(permissions, fromViewController: nil, handler: { (result, error) -> Void in
        print("[LOGIN] done: \(error) \(result)")
        if error != nil {
          completion?(error: error)
        }
        else {
          // Loop back to login
          self.login(completion)
        }
      })
      return
    }
    self._loginWithToken(token, completion: completion)
  }

  private func _loginWithToken(token: FBSDKAccessToken, completion: ((error: NSError!) -> Void)!) {
    print("[LOGIN] Firebase start...")
    connection.authWithOAuthProvider("facebook", token: token.tokenString) { (error, auth) -> Void in
      print("[LOGIN] Firebase done: \(error) \(auth)")
      self.auth = auth
      self.player = Player(playerID: self.playerID)
      completion?(error: error)
    }
  }

  func logout() {
    print("[LOGIN] Logged out.")
    self.auth = nil
    Account.fb.logOut()
  }

  var isLoggedIn:Bool {
    return self.auth != nil
  }

  var playerID:String {
    return (self.auth?.uid)!
  }
}
