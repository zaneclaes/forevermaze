//
//  Utils.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/23/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation

class Utils {

  static let reservedProperties = ["description", "connection", "snapshot"]

  static func getWritableProperties(obj: AnyObject!) -> [String] {
    return self.getWritableClassProperties(object_getClass(obj))
  }

  static func getWritableClassProperties(klass: AnyClass!) -> [String] {
    let superclass:AnyClass! = class_getSuperclass(klass)
    var dynamicProperties = superclass == nil ? [String]() : getWritableClassProperties(superclass)
    guard klass != NSObject.self else {
      return dynamicProperties
    }

    var propertyCount = UInt32(0)
    let properties = class_copyPropertyList(klass, &propertyCount)
    for var i = 0; i < Int(propertyCount); i++ {
      let property = properties[i]
      let propertyName = property_getName(property)
      // n.b., the `attributes` array should tell us if the property is dynamic
      // Sadly it seems proken in Swift
      // c.f., https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
      // We should have been able to look for `,D,` to indicate @dynamic
      let attributes = String(CString: property_getAttributes(property), encoding: NSUTF8StringEncoding)!
      if (attributes.rangeOfString(",R,") != nil) {
        // Readonly property
        continue
      }

      let prop = String(CString: propertyName, encoding: NSUTF8StringEncoding)!
      if !reservedProperties.contains(prop) {
        dynamicProperties.append(prop)
      }
    }
    free(properties)

    return dynamicProperties
  }
}
