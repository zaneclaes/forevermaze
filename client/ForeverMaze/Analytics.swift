//
//  Analytics.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/7/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import Foundation

enum EventName {
  case StartGame, EndGame, BeatLevel, ViewScene, Share, Error
  
  var description:String {
    switch self {
    case StartGame: return "StartGame"
    case EndGame:   return "EndGame"
    case BeatLevel: return "BeatLevel"
    case ViewScene: return "ViewScene"
    case Share:     return "Share"
    case Error:     return "Error"
    }
  }

}

class Analytics {
  static func log(event:EventName, params:NSDictionary? = nil) {
    if params != nil {
      FBSDKAppEvents.logEvent(event.description, parameters: params! as [NSObject : AnyObject])
    }
    else {
      FBSDKAppEvents.logEvent(event.description)
    }
  }
  
  static func view(screen: String) {
    FBSDKAppEvents.logEvent(EventName.ViewScene.description, parameters: ["screen":screen])
  }
}
