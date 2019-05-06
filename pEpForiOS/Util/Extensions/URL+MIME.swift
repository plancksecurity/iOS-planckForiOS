//
//  URL+MIME.swift
//  pEp
//
//  Created by Andreas Buff on 24.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension URL {
    public func mimeType() -> String? {
        return MimeTypeUtil()?.mimeType(fileExtension: pathExtension)
    }
}
