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

class Utils {
  // Given an object and a filtration block, return an array of all properties on the object.
  static func getProperties(obj: AnyObject!, filter: ((String, String) -> (Bool))!) -> [String] {
    return self.getClassProperties(object_getClass(obj), filter: filter)
  }
  
  static func getClassProperties(klass: AnyClass!, filter: ((String, String) -> (Bool))!) -> [String] {
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
      // Sadly it seems proken in Swift
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
}
