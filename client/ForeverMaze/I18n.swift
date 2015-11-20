//
//  I18n.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/23/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation

class I18n {

  static func t(key: String!) -> String! {
    return NSLocalizedString(key, comment: "")
  }
}
