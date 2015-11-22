//
//  Account.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import Firebase
import PromiseKit
import CocoaLumberjack

class Account {
  static let current: Account = Account()
  private static let fb: FBSDKLoginManager = FBSDKLoginManager()

  var player: LocalPlayer?
  private var auth: FAuthData? = nil
  private let connection: Firebase
  let permissions : Array<String> = ["public_profile", "email", "user_friends"]

  init() {
    self.connection = Firebase(url: Config.firebaseUrl)
  }

  func resume() -> Promise<String!> {
    guard let token: FBSDKAccessToken = FBSDKAccessToken.currentAccessToken() else {
      return Promise { fulfill, reject in
        fulfill(nil)
      }
    }
    return self._handOffToken(token)
  }

  func login() -> Promise<String!> {
    return self._loginToFacebook().then { (token) -> Promise<String!> in
      return self._handOffToken(token)
    }
  }

  private func _loginToFacebook() -> Promise<FBSDKAccessToken> {
    guard let token: FBSDKAccessToken = FBSDKAccessToken.currentAccessToken() else {
      DDLogDebug("[ACCOUNT] Facebook start...")

      return Promise { fulfill, reject in
        Account.fb.logInWithReadPermissions(permissions, fromViewController: nil, handler: { (result, error) -> Void in
          if error == nil {
            fulfill(FBSDKAccessToken.currentAccessToken())
          }
          else {
            reject(error)
          }
        })
      }
    }
    return Promise { fulfill, reject in
      fulfill(token)
    }
  }


  private func _handOffToken(token: FBSDKAccessToken) -> Promise<String!> {
    DDLogDebug("[ACCOUNT] Firebase start...")

    return Promise { fulfill, reject in
      self.connection.authWithOAuthProvider("facebook", token: token.tokenString, withCompletionBlock: { (error, auth) -> Void in
        if error == nil {
          self.auth = auth
          // self.player = Player(playerID: self.playerID)
          fulfill(self.playerID)
        }
        else {
          reject(error)
        }
      })
    }
  }

  func logout() {
    DDLogDebug("[ACCOUNT] Logged out.")
    self.auth = nil
    self.player = nil
    Account.fb.logOut()
  }

  var isLoggedIn:Bool {
    return self.auth != nil
  }

  var playerID:String {
    return (self.auth?.uid)!
  }
}
