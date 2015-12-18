//
//  Utils.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/23/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation
import PromiseKit
import Firebase
import CocoaLumberjack

// Given a block of code, time how long it takes to run.
func timer(block: () -> (), name: String) -> Void {
  let start = NSDate().timeIntervalSince1970
  block()
  let elapsed = NSDate().timeIntervalSince1970 - start
  DDLogInfo("[\(name)] \(elapsed < 0.00001 ? 0 : elapsed)")
}

func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
  return min(max(value, lower), upper)
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGPoint) -> CGPoint {
  return CGPoint(x: point.x * scalar.x, y: point.y * scalar.y)
}

func / (point: CGPoint, scalar: CGPoint) -> CGPoint {
  return CGPoint(x: point.x / scalar.x, y: point.y / scalar.y)
}

func distance(p1:CGPoint, p2:CGPoint) -> CGFloat {
  return CGFloat(hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y)))
}

func round(point:CGPoint) -> CGPoint {
  return CGPoint(x: round(point.x), y: round(point.y))
}

func floor(point:CGPoint) -> CGPoint {
  return CGPoint(x: floor(point.x), y: floor(point.y))
}

func ceil(point:CGPoint) -> CGPoint {
  return CGPoint(x: ceil(point.x), y: ceil(point.y))
}

func getProperties(obj: AnyObject!, filter: ((String, String) -> (Bool))!) -> [String] {
  return getClassProperties(object_getClass(obj), filter: filter)
}

func getClassProperties(klass: AnyClass!, filter: ((String, String) -> (Bool))!) -> [String] {
  let superclass:AnyClass! = class_getSuperclass(klass)
  var dynamicProperties = superclass == nil ? [String]() : getClassProperties(superclass, filter: filter)
  guard klass != NSObject.self else {
    return dynamicProperties
  }

  var propertyCount = UInt32(0)
  let properties = class_copyPropertyList(klass, &propertyCount)
  for var i = 0; i < Int(propertyCount); i++ {
    let property = properties[i]
    let propertyName = String(CString: property_getName(property), encoding: NSUTF8StringEncoding)!
    // n.b., the `attributes` array should tell us if the property is dynamic
    // Sadly it seems broken in Swift
    // c.f., https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
    // We should have been able to look for `,D,` to indicate @dynamic
    let attributes = String(CString: property_getAttributes(property), encoding: NSUTF8StringEncoding)!
    if (filter(propertyName, attributes)) {
      // Readonly property
      continue
    }
    dynamicProperties.append(propertyName)
  }
  free(properties)

  return dynamicProperties
}

