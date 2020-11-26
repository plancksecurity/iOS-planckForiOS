//
//  Attachment+ContentDispositionType+PEPContentDisposition.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Attachment.ContentDispositionType {
    static func from(
        contentDisposition: PEPContentDisposition) -> Attachment.ContentDispositionType {
        switch contentDisposition {
        case .attachment:
            return .attachment
        case .inline:
            return .inline
        case .other:
            return .other
        }
    }
}
