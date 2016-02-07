//
//  Share.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/7/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import Foundation

class Share {
  static func shareOnFacebook() {
    let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
    content.contentURL = NSURL(string: "http://ForeverMaze.com")
    content.contentTitle = I18n.t("share.title")
    content.contentDescription = I18n.t("share.body")
    content.imageURL = NSURL(string: "http://forevermaze.com/images/facebook.png")
    FBSDKShareDialog.showFromViewController(UIApplication.sharedApplication().windows.first!.rootViewController, withContent: content, delegate: nil)
  }
}
