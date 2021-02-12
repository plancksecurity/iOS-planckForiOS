//
//  Attachment+ContentID.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.11.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension Attachment {
    /// Tries to extract the contentID of the attachment from the `filename` field.
    /// Returns the CID (without `cid:` or `cid://`) if `filename` contains it.
    /// Otherwize `nil` is returned.
    public var contentID: String? {
        guard let fn = fileName else {
            return nil
        }
        return fn.extractCid()
    }
}
