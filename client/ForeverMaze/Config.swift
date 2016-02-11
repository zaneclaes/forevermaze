//
//  Config.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import CocoaLumberjack
import DeviceKit
import Firebase
import PromiseKit
import SpriteKit
import ChimpKit
  
class Config {

  static let debug:Bool = false
  static let godMode:Bool = true
  
  // API Keys & Config
  static let firebaseUrl:String = "https://forevermaze.firebaseio.com"
  static let mailChimpApiKey:String = "519b62ef83a56e62c6d0e31cad197d0f-us7"
  static var mailChimpListId:String = "7ae703d89a"
  
  // UI, Assets & Fonts
  static let headerFont:String = "AvenirNext-Bold"
  static let bodyFont:String = "AvenirNext"
  static let worldAtlas = SKTextureAtlas(named: "world")
  static let sceneTransition = SKTransition.crossFadeWithDuration(1)
  static let objectScale:CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 0.5 : 1
  
  // Misc:
  static let device = Device()
  static let timeout:NSTimeInterval = 30
  static let baseErrorDomain = NSBundle.mainBundle().bundleIdentifier
  static let stepTime = 0.4
  static let tileBuffer = 5
  static let flipTileCost = 15
  static let maxHighScores = 100
  static let minOtherPlayerSpawnDistance:UInt = 20
  static let depressionAudioDistance:CGFloat = 1200 // The tile distance for the audio fading (in points, will be scaled by objectScale)
  
  // Config from server::
  static var worldSize = MapSize(width: 100, height: 100)
  static var shareRoll:Int = 4
  static var shareDelay:NSTimeInterval = 259200
  static var happinessPotionDuration:NSTimeInterval = 30
  static var remote:FDataSnapshot!
  static var toggleRaisedRoll:Int = 5
  static var levels = Array<Level>()

  static func setup() -> Promise<Void> {
    DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
    DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
    defaultDebugLevel = Config.debug ? DDLogLevel.All : DDLogLevel.Info

    ChimpKit.sharedKit().apiKey = Config.mailChimpApiKey
    DDLogInfo("[CONFIG] \(device)")

    //Firebase.defaultConfig().persistenceEnabled = true
    return Data.loadSnapshot("/config").then { (snapshot) -> Promise<Void> in
      remote = snapshot
      return Promise { fulfill, reject in
        if remote == nil {
          reject(Errors.network)
          return
        }
        self.toggleRaisedRoll = (remote?.childSnapshotForPath("toggleRaisedRoll").value as! NSNumber).integerValue
        self.shareRoll = (remote?.childSnapshotForPath("shareRoll").value as! NSNumber).integerValue
        self.shareDelay = (remote?.childSnapshotForPath("shareDelay").value as! NSNumber).doubleValue
        self.happinessPotionDuration = (remote?.childSnapshotForPath("happinessPotionDuration").value as! NSNumber).doubleValue
        self.mailChimpListId = remote?.childSnapshotForPath("mailChimpListId").value as! String
        
        let worldSize = remote?.childSnapshotForPath("worldSize")
        let width:Int = (worldSize?.childSnapshotForPath("width").value as! NSNumber).integerValue
        let height:Int = (worldSize?.childSnapshotForPath("height").value as! NSNumber).integerValue
        self.worldSize = MapSize(width: UInt(max(10,width)), height: UInt(max(10,height)))

        // Load levels
        let levels = remote!.childSnapshotForPath("levels")
        for data in levels.children {
          let level = Level(snapshot: data as! FDataSnapshot, number: UInt(self.levels.count))
          self.levels.append(level)
        }

        fulfill()
      }
    }
  }

  static var screenTiles:MapSize {
    return MapSize(width: 11, height: 11)// n.b., this should always be odd, to enforce a single point as the center of a mapbox
  }

}
