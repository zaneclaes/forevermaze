//
//  User.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/20/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import SpriteKit
import PromiseKit
import Firebase
import Kingfisher

class Player : Mobile {

  let playerID: String!
  override var allowsForDynamicUnloading:Bool {
    return false
  }
  dynamic var lastLogin: NSNumber? = nil
  dynamic var online: Bool = false
  dynamic var unlockedTiles:Array<String> = []
  dynamic var numHappiness:Int = 0
  dynamic var numAnger:Int = 0
  dynamic var numSadness:Int = 0
  dynamic var numFear:Int = 0
  dynamic var emoji:Int = 0
  dynamic var currentLevel:Int = 0
  dynamic var depressionPos:String = ""
  dynamic var score:UInt = 0
  dynamic var highScore:UInt = 0
  dynamic var wishingWells:Array<String> = []
  dynamic var numHappinessPotions:Int = 0
  dynamic var happinessPotionTimeRemaining:NSTimeInterval = 0

  init (playerID: String!) {
    self.playerID = playerID
    super.init(firebasePath: playerID == nil ? nil : "/players/\(playerID)")
    self.alias = self.alias == nil ? "Player" : self.alias
  }
  
  override var assetName:String {
    return "hero"
  }

  override var guardedProperties:[String] {
    return super.guardedProperties + ["alias"]
  }

  override var description:String {
    return "<\(self.dynamicType) \(playerID)>: \(alias == nil ? "" : alias!) @\(self.coordinate)->\(self.direction)"
  }
  
  override var trackerTexture:SKTexture {
    return Account.player!.sprite.texture!
  }

  override var id:String {
    return "/players/\(self.playerID)"
  }
  
  var facebookId:String {
    return self.playerID.componentsSeparatedByString(":").last!
  }

  var isCurrentUser: Bool {
    return Account.isLoggedIn && Account.playerID == self.playerID
  }

  func hasUnlockedTileAt(coordinate: Coordinate) -> Bool {
    return self.unlockedTiles.indexOf(coordinate.description) != nil
  }

  var depressionCoordinate:Coordinate! {
    guard Account.player!.numUnlockedTiles > Account.player!.level.depressionSpawnAfterTiles else {
      return nil
    }
    if self.depressionPos.rangeOfString("x") == nil && Account.player!.numUnlockedTiles > Account.player!.level.depressionSpawnAfterTiles {
      // Spawn depression.
      let dist = Int(self.level.depressionSpawnDistance / 2)
      let x = (arc4random_uniform(2) == 0 ? 1 : -1) * dist
      let y = (arc4random_uniform(2) == 0 ? 1 : -1) * dist
      let pos = Coordinate(xIndex: x + self.coordinate.xIndex, yIndex: y + self.coordinate.yIndex)
      self.depressionPos = pos.description
      return pos
    }
    guard self.depressionPos.rangeOfString("x") != nil else {
      return nil
    }
    return Coordinate(desc: self.depressionPos)
  }

  var level:Level {
    let l = clamp(self.currentLevel, lower: 0, upper: Config.levels.count - 1)
    return Config.levels[l]
  }
  
  func getProfilePicture(size: CGSize) -> Promise<UIImage> {
    let (promise, fulfill, reject) = Promise<UIImage>.pendingPromise()
    let url = "https://graph.facebook.com/\(facebookId)/picture?width=\(Int(size.width))&height=\(Int(size.height))"
    let resource = Resource(downloadURL: NSURL(string:url)!)
    KingfisherManager.sharedManager.retrieveImageWithResource(resource, optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) -> () in
      if image != nil {
        fulfill(image!)
      }
      else if error != nil {
        reject(error!)
      }
      else {
        reject(Errors.network)
      }
    }
    return promise
  }
}
