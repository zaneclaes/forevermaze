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
  private static let fb: FBSDKLoginManager = FBSDKLoginManager()
  private static let connection = Firebase(url: Config.firebaseUrl)
  static let permissions : Array<String> = ["public_profile", "email", "user_friends"]

  static var player: LocalPlayer?
  static private var auth: FAuthData? = nil

  init() {
    NSException(name: "NotImplemented", reason: "Static implementation only.", userInfo: nil).raise()
  }

  static func resume() -> Promise<LocalPlayer!> {
    guard let token: FBSDKAccessToken = FBSDKAccessToken.currentAccessToken() else {
      return Promise { fulfill, reject in fulfill(nil) }
    }
    return self._handOffToken(token)
  }

  static func login() -> Promise<LocalPlayer!> {
    return self._loginToFacebook().then { (token) -> Promise<LocalPlayer!> in
      return self._handOffToken(token)
    }
  }

  static private func _loginToFacebook() -> Promise<FBSDKAccessToken> {
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

  static private func _handOffToken(token: FBSDKAccessToken) -> Promise<LocalPlayer!> {
    DDLogDebug("[ACCOUNT] Firebase start...")

    return Promise { fulfill, reject in
      self.connection.authWithOAuthProvider("facebook", token: token.tokenString, withCompletionBlock: { (error, auth) -> Void in
        if error == nil && auth?.uid != nil {
          self.auth = auth
          fulfill(auth?.uid)
        }
        else {
          reject(error)
        }
      })
    }.then { (playerID) -> Promise<LocalPlayer!> in
      return self._loadPlayer(playerID)
    }
  }

  static private func _loadPlayer(playerID: String!) -> Promise<LocalPlayer!> {
    DDLogDebug("[ACCOUNT] Loading player \(playerID)...")
    return LocalPlayer.loadLocalPlayerID(playerID)
  }

  static func logout() {
    DDLogDebug("[ACCOUNT] Logged out.")
    self.auth = nil
    self.player = nil
    Account.fb.logOut()
  }

  static var isLoggedIn:Bool {
    return self.auth != nil
  }

  static var playerID:String {
    return (self.auth?.uid)!
  }
}
