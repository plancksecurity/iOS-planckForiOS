//
//  String+Attachment.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {
    public func firstMatch(pattern: String, rangeNumber: Int = 1) -> String? {
        do {
            let regex = try NSRegularExpression(
                pattern: pattern, options: [])
            if let match = regex.firstMatch(in: self, options: [], range: wholeRange()) {
                let r = match.range(at: rangeNumber)
                let s = (self as NSString).substring(with: r)
                return s
            }
            return nil
        } catch let err as NSError {
            Log.shared.errorAndCrash(component: #function, error: err)
            return nil
        }
    }

    /**
     The actual cid in a String like "cid://someCid" or "cid:someCid".
     */
    public func extractCid() -> String? {
        return firstMatch(pattern: "^cid:(?://)?(.+)$")
    }

    /**
     - Return: The filename part in a URL String of the form "file://filename"
     */
    public func extractFileName() -> String? {
        return firstMatch(pattern: "^file://(.+)$")
    }
}
