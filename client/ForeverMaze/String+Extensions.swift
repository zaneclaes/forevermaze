//
//  String+Extensions.swift
//  ForeverMaze
//
//  Created by Zane Claes on 11/29/15.
//  Copyright © 2015 inZania LLC. All rights reserved.
//

import Foundation

extension String {
  init(htmlEncodedString: String) {
    let encodedData = htmlEncodedString.dataUsingEncoding(NSUTF8StringEncoding)!
    let attributedOptions : [String: AnyObject] = [
      NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
      NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
    ]
    let attributedString = try? NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
    self.init(attributedString?.string)
  }
}
