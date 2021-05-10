//
//  String+Attachment.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

extension String {
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

    /// Extracts filename or content ID (cid) in case one of the following prefixes is found:
    /// cid://
    /// cid:
    /// file://
    /// Otherwize the unmodified string is returned.
    ///
    /// - Returns: If prefixed: the parsed filename/cid
    ///            Otherwize the unmodified string
    public func extractFileNameOrCid() -> String {
        if let cid = self.extractCid() {
            return cid
        } else {
            return self.extractFileName() ?? self
        }
    }
}
