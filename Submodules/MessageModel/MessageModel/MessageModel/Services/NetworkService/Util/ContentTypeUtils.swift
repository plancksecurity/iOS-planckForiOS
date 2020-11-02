//
//  ContentTypeUtils.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 07/05/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

struct ContentTypeUtils {
    struct ContentType {
        static let multipartMixed = "multipart/mixed"
        static let multipartEncrypted = "multipart/encrypted"
        static let multipartRelated = "multipart/related"
        static let multipartAlternative = "multipart/alternative"
    }
}
