//
//  StringExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public extension String {
    static let internalRecipientDelimiter = ","
    static let externalRecipientDelimiter = ", "
    static let comp = "String.Extensions"

    /**
     Mimicks the `NSString` version.
     */
    public func stringByReplacingCharactersInRange(range: NSRange,
                                                   withString replacement: String) -> String {
        let s = self as NSString
        return s.stringByReplacingCharactersInRange(range, withString: replacement)
    }

    /**
     Assumes that the `String` is a list of recipients, delimited by comma (","), and you
     can only edit the last one. This is very similar to the way the native iOS mail app
     handles contact input.
     - Returns: The last part of a contact list that can still be edited.
     */
    public func unfinishedRecipientPart() -> String {
        let comps = self.componentsSeparatedByString(String.internalRecipientDelimiter)
        if comps.count == 0 {
            return self
        } else {
            return comps.last!.trimmedWhiteSpace()
        }
    }

    /**
     - Returns: The part of a recipient list that connot be edited anymore.
     */
    public func finishedRecipientPart() -> String {
        let comps = self.componentsSeparatedByString(String.internalRecipientDelimiter)
        if comps.count == 1 {
            return ""
        } else {
            let ar = comps[0..<comps.count-1].map({$0.trimmedWhiteSpace()})
            return ar.joinWithSeparator(String.externalRecipientDelimiter)
        }
    }

    /**
     Trims whitespace from back and front.
     */
    public func trimmedWhiteSpace() -> String {
        do {
            let regex = try NSRegularExpression.init(pattern: "^\\s*?(\\S+)\\s*?$",
                                                     options: [])
            let matches = regex.matchesInString(self, options: [],
                                          range: NSMakeRange(0, self.characters.count))
            if matches.count > 0 {
                let m = matches[0]
                let r = m.rangeAtIndex(1)
                if r.location != NSNotFound {
                    let s = self as NSString
                    let result = s.substringWithRange(r)
                    return result
                }
            }

        } catch let err as NSError {
            Log.errorComponent(String.comp, error: err)
        }
        return self
    }
}