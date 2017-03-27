//
//  NSData+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

extension Data {
    public func stringEncodingFromIANACharset(_ charset: String) -> String.Encoding {
        let enc = CFStringConvertIANACharSetNameToEncoding(charset as CFString!)
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(enc))
    }

    public func toStringWithIANACharset(_ charset: String?) -> String? {
        if let cs = charset {
            let enc = stringEncodingFromIANACharset(cs)
            return String.init(data: self, encoding: enc)
        } else {
            return String.init(data: self, encoding: String.Encoding.utf8)
        }
    }
}
