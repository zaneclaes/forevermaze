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
  
class Config {

  static let debug:Bool = false
  static let godMode:Bool = true
  static let firebaseUrl:String = "https://forevermaze.firebaseio.com"
  static let worldAtlas = SKTextureAtlas(named: "world")
  static let font:String = "AvenirNext-Bold"
  static let device = Device()
  static let timeout:NSTimeInterval = 30
  static let baseErrorDomain = NSBundle.mainBundle().bundleIdentifier
  static let stepTime = 0.4
  static let tileBuffer = 5
  static let objectScale:CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 0.5 : 1
  static let flipTileCost = 10
  static let minOtherPlayerSpawnDistance:UInt = 20
  static var worldSize = MapSize(width: 100, height: 100)
  static var remote:FDataSnapshot!
  static var levels = Array<Level>()

  static func setup() -> Promise<Void> {
    DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
    DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
    defaultDebugLevel = Config.debug ? DDLogLevel.All : DDLogLevel.Info

    DDLogInfo("[CONFIG] \(device)")

    //Firebase.defaultConfig().persistenceEnabled = true
    return Data.loadSnapshot("/config").then { (snapshot) -> Promise<Void> in
      remote = snapshot
      return Promise { fulfill, reject in
        if remote == nil {
          reject(Errors.network)
          return
        }
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
