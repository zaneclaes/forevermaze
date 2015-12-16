//
//  Errors.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/23/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation

class Errors {

  static let network = NSError(
    domain: Config.baseErrorDomain! + ".network",
    code: 1,
    userInfo: [NSLocalizedDescriptionKey : I18n.t("errors.network")]
  )

  static let data = NSError(
    domain: Config.baseErrorDomain! + ".data",
    code: 2,
    userInfo: [NSLocalizedDescriptionKey : I18n.t("errors.data")]
  )

}
