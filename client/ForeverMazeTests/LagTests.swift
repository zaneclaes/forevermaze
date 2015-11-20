//
//  LoadingTests.swift
//  ForeverMaze
//
//  Created by Zane Claes on 1/3/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import XCTest
import Firebase

class LagTests : XCTestCase {

  let firebaseUrl = "https://forevermaze.firebaseio.com"
  let timeLimit:NSTimeInterval = 2.0 // Max acceptable load time for any one tile
  let stepTime = 0.2
  let tilesPerStep = 20
  let stepsToTake = 100

  /**
   * Run this function once to ensure the database is configured
   */
  func testSetupDatabase() {

    let expectation = expectationWithDescription("Setup database")
    let mapSize = CGSizeMake(100,100) // Size of the world.
    let tiles = Firebase(url: firebaseUrl).childByAppendingPath("/tiles_test")
    var loading = 1

    tiles.observeSingleEventOfType(.Value, withBlock: { snapshot in
      for (var x=0; x<Int(mapSize.width); x++) {
        for (var y=0; y<Int(mapSize.height); y++) {
          if !snapshot.hasChild("\(x)x\(y)") {
            let tile = tiles.childByAppendingPath("\(x)x\(y)")
            let val = Int(arc4random_uniform(10))
            loading++
            tile.childByAppendingPath("value").setValue(val, withCompletionBlock: { (error, fb) -> Void in
              loading--
              if loading == 0 {
                expectation.fulfill()
              }
            })
          }
          loading--
          if loading == 0 {
            expectation.fulfill()
          }
        }
      }
    })

    waitForExpectationsWithTimeout(300) { error in
      if error != nil {
        print("Error: \(error!.localizedDescription)")
      }
    }
  }

  /**
   * Main test function
   * It schedules `stepsToTake` invocations of the `testStep` function,
   * separated by `stepTime` delay between each step.
   */
  var stepsRemaining = 0
  func testWalking() {
    let expectation = expectationWithDescription("Load tiles")
    let maxTime = self.timeLimit + self.stepTime * Double(stepsToTake)

    for (var x=0; x<stepsToTake; x++) {
      let delay = Double(x) * stepTime
      let data = ["x":x, "ex": expectation]
      stepsRemaining++
      NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: Selector("testStep:"), userInfo: data, repeats: false)
    }
    waitForExpectationsWithTimeout(maxTime) { error in
      if error != nil {
        print("Error: \(error!.localizedDescription)")
      }
    }
  }

  /**
   * Helper function to test a single step (executes `tilesPerStep` number of tile loads)
   */
  func testStep(timer : NSTimer) {
    let tiles = Firebase(url: firebaseUrl).childByAppendingPath("/tiles_test")
    let data = timer.userInfo as! Dictionary<String, AnyObject>
    let x = data["x"] as! Int
    let expectation = data["ex"] as! XCTestExpectation
    var loading = 0

    for (var y=0; y<tilesPerStep; y++) {
      loading++
      let startTime = NSDate().timeIntervalSince1970
      tiles.childByAppendingPath("\(x)x\(y)").observeSingleEventOfType(.Value, withBlock: { snapshot in
        let time = NSDate().timeIntervalSince1970 - startTime
        XCTAssert(time < self.timeLimit,"Tile \(x)x\(y) took \(time)")
        loading--
        if loading == 0 {
          self.stepsRemaining--
          print("Steps Remaining: \(self.stepsRemaining)")
          if self.stepsRemaining == 0 {
            expectation.fulfill()
          }
        }
      })
    }
  }

}
