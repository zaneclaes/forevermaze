//
//  Audio.swift
//  ForeverMaze
//
//  Created by Zane Claes on 2/10/16.
//  Copyright © 2016 inZania LLC. All rights reserved.
//

import AVFoundation
import CocoaLumberjack

class Audio {
  
  let heroTrack:AVAudioPlayer
  let depressionTrack:AVAudioPlayer
  
  private static let FADE_DURATION = 1.0
  private static let FADE_VELOCITY = 5.0
  
  private var targetVolumes:[String:Float] = [:]
  
  init() {
    let fpHero = NSBundle.mainBundle().URLForResource("hero", withExtension: "mp3")
    try! heroTrack = AVAudioPlayer(contentsOfURL: fpHero!)
    heroTrack.prepareToPlay()
    heroTrack.volume = 0
    heroTrack.numberOfLoops = -1
    
    let fpDepression = NSBundle.mainBundle().URLForResource("depression", withExtension: "mp3")
    try! depressionTrack = AVAudioPlayer(contentsOfURL: fpDepression!)
    depressionTrack.prepareToPlay()
    depressionTrack.volume = 0
    depressionTrack.numberOfLoops = -1
    
    play()
  }
  
  func fadeIn(track: AVAudioPlayer) {
    guard track.volume < 1 else {
      return
    }
    let fader = AudioFader(player: track)
    fader.fadeIn(Audio.FADE_DURATION, velocity: Audio.FADE_VELOCITY, onFinished: nil)
  }
  
  func fadeOut(track: AVAudioPlayer) {
    guard track.volume > 0 else {
      return
    }
    let fader = AudioFader(player: track)
    fader.fadeOut(Audio.FADE_DURATION, velocity: Audio.FADE_VELOCITY, onFinished: nil)
  }
  
  func fadeToTrack(track: AVAudioPlayer) {
    for otherTrack in tracks {
      if track == otherTrack {
        fadeIn(otherTrack)
      }
      else {
        fadeOut(otherTrack)
      }
    }
  }
  
  func pause() {
    for track in tracks {
      track.pause()
    }
  }
  
  func play() {
    for track in tracks {
      track.play()
    }
  }
  
  var tracks:[AVAudioPlayer] {
    return [heroTrack,depressionTrack]
  }
  
  static var sharedInstance:Audio {
    return audio
  }
  
}

private let audio = Audio()
