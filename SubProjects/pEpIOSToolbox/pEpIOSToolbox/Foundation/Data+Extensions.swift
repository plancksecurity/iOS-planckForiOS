//
//  NSData+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Data {
    public func stringEncodingFromIANACharset(_ charset: String) -> String.Encoding {
        let enc = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(enc))
    }

    public func toStringWithIANACharset(_ charset: String?) -> String? {
        if let cs = charset {
            let enc = stringEncodingFromIANACharset(cs)
            return String(data: self, encoding: enc)?.applyingDos2Unix()
        } else if let tryUtf8 = String(data: self,
                                       encoding: String.Encoding.utf8)?.applyingDos2Unix() {
            return tryUtf8
        } else if let tryAscii = String(data: self,
                                        encoding: String.Encoding.ascii)?.applyingDos2Unix() {
            return tryAscii
        }
        return nil
    }
}
