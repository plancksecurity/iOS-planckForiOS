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
        public static let multipartMixed = "multipart/mixed"
        public static let multipartEncrypted = "multipart/encrypted"
        public static let multipartRelated = "multipart/related"
        public static let multipartAlternative = "multipart/alternative"
    }
}
