//
//  Regex.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 A collection of static regular expressions for use in extensions,
 to prevent their creation and compilation in every function call.
 */
class Regex {
    static let gmailRegex = try! NSRegularExpression(
        // character classes: https://en.wikipedia.org/wiki/Unicode_character_property
        pattern: "[-_[\\p{Ll}\\p{Lu}\\p{Nd}]]+@gmail\\.[a-z]+",
        options: [])

    static let moduleTitleRegex = try! NSRegularExpression(
        pattern: "<pEpForiOS\\.(\\w+):", options: [])

    static let unquoteRegex = try! NSRegularExpression(
        pattern: "^\"(.*)\"$", options: [])

    static let probablyValidEmailRegex = try! NSRegularExpression(
        pattern: "^[^@,]+@[^@,]+$", options: .caseInsensitive)

    static let namePartOfEmailRegex = try! NSRegularExpression(pattern: "^([^@]+)@", options: [])

    static let endWhiteSpaceRegex = try! NSRegularExpression(
        pattern: "^(.*?)\\s*$", options: [])

    static let newlineRegex = try! NSRegularExpression(
        pattern: "(\\n|\\r\\n)+", options: [])

    static let threeOrMoreNewlinesRegex = try! NSRegularExpression(
        pattern: "(\\n|\\r\\n){3,}", options: [])

    static let fileExtensionRegex = try! NSRegularExpression(
        pattern: "^([^.]+)\\.([^.]+)$", options: [])
}
