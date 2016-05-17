//
//  NSData+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSData {
    public func stringEncodingFromIANACharset(charset: String) -> NSStringEncoding {
        let enc = CFStringConvertIANACharSetNameToEncoding(charset)
        return CFStringConvertEncodingToNSStringEncoding(enc)
    }

    public func toStringWithIANACharset(charset: String?) -> String? {
        if let cs = charset {
            let enc = stringEncodingFromIANACharset(cs)
            return String.init(data: self, encoding: enc)
        } else {
            return String.init(data: self, encoding: NSUTF8StringEncoding)
        }
    }

}