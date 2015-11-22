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

class Config {
  static let firebaseUrl:String = "https://forevermaze.firebaseio.com"

  static func setup() {
    let device = Device()

    DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
    DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
    defaultDebugLevel = DDLogLevel.Info

    DDLogInfo("[CONFIG] \(device)")
  }
}
