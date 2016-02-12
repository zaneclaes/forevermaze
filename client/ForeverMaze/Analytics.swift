//
//  Analytics.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/7/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import Foundation

enum EventName {
  case StartGame, EndGame, BeatLevel, ViewScene, Share, Error, Experiment
  
  var description:String {
    switch self {
    case StartGame: return "StartGame"
    case EndGame:   return "EndGame"
    case BeatLevel: return "BeatLevel"
    case ViewScene: return "ViewScene"
    case Share:     return "Share"
    case Error:     return "Error"
    case Experiment:return "Experiment"
    }
  }

}

class Analytics {
  static func getTreatment(experimentName: String, treatments: [String]) -> String {
    let cacheKey = "\(experimentName)_\(treatments.joinWithSeparator("_"))"
    let existingTreatment = NSUserDefaults.standardUserDefaults().valueForKeyPath(cacheKey)
    if existingTreatment != nil && treatments.indexOf(existingTreatment as! String) != nil {
      return existingTreatment as! String
    }
    let treatment = treatments[Int(arc4random_uniform(UInt32(treatments.count)))]
    NSUserDefaults.standardUserDefaults().setValue(treatment, forKey: cacheKey)
    NSUserDefaults.standardUserDefaults().synchronize()
    log(.Experiment, params: ["experimentName": experimentName, "treatment": treatment])
    return treatment
  }
  
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
