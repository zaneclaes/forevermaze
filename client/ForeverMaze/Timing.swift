//
//  Timing.swift
//  ForeverMaze
//
//  Created by Zane Claes on 12/17/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import CocoaLumberjack

func timer(block: () -> (), name: String) -> Void {
  let start = NSDate().timeIntervalSince1970
  block()
  let elapsed = NSDate().timeIntervalSince1970 - start
  DDLogInfo("[\(name)] \(elapsed < 0.00001 ? 0 : elapsed)")
}
