//
//  String+Attachment.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {
    public func extractCid() -> String? {
        do {
            let regex = try NSRegularExpression(
                pattern: "^cid:(.+)$", options: [])
            if let match = regex.firstMatch(in: self, options: [], range: wholeRange()) {
                let r = match.rangeAt(1)
                let s = (self as NSString).substring(with: r)
                return s
            }
            return nil
        } catch let err as NSError {
            Log.error(component: #function, error: err)
            return nil
        }
    }
}
