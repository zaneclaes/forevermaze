//
//  AppDelegate.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func application(application: UIApplication,
    openURL url: NSURL,
    sourceApplication: String?,
    annotation: AnyObject) -> Bool {
      return FBSDKApplicationDelegate.sharedInstance().application(
        application,
        openURL: url,
        sourceApplication: sourceApplication,
        annotation: annotation)
  }

  func applicationWillResignActive(application: UIApplication) {
  }

  func applicationDidEnterBackground(application: UIApplication) {
  }

  func applicationWillEnterForeground(application: UIApplication) {
  }

  func applicationDidBecomeActive(application: UIApplication) {
    FBSDKAppEvents.activateApp()
  }

  func applicationWillTerminate(application: UIApplication) {
  }


}

