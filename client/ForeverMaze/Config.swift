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

class Config {
  static let firebaseUrl:String = "https://forevermaze.firebaseio.com"
  static let device = Device()
  static let timeout = 30
  static let baseErrorDomain = NSBundle.mainBundle().bundleIdentifier
  static let stepTime = 0.01
  static var worldSize = MapSize(width: 100, height: 100)
  static var remote:FDataSnapshot!

  static func setup() -> Promise<Void> {
    DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
    DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
    defaultDebugLevel = DDLogLevel.Info

    DDLogInfo("[CONFIG] \(device)")
    return Data.loadSnapshot("/config").then { (snapshot) -> Promise<Void> in
      remote = snapshot
      return Promise { fulfill, reject in
        let worldSize = remote?.childSnapshotForPath("worldSize")
        let width:Int = (worldSize?.childSnapshotForPath("width").value as! NSNumber).integerValue
        let height:Int = (worldSize?.childSnapshotForPath("height").value as! NSNumber).integerValue
        self.worldSize = MapSize(width: UInt(max(10,width)), height: UInt(max(10,height)))

        fulfill()
      }
    }
  }

  static var screenTiles:MapSize {
    return MapSize(width: 11, height: 11)// n.b., this should always be odd, to enforce a single point as the center of a mapbox
  }

}
