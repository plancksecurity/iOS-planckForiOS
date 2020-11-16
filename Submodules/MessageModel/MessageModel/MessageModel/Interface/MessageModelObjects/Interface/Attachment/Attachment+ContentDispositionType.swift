//
//  Server+ContentDispositionType.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Attachment {

    // Mirrors the Engines content_disposition type, including the raw values.
    public enum ContentDispositionType: Int16 {
        case attachment = 0
        case inline = 1
        case other = -1 // Not sure what usecase this is for. Added to be consistant with the Engine
        public static func ==(lhs: ContentDispositionType, rhs: ContentDispositionType) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }

    /// Wheter or not the attachment is inlined in a HTML mail body.
    public var isInlined: Bool {
        return contentDisposition == .inline
    }
}
