//
//  ContentTypeUtils.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 07/05/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

public struct ContentTypeUtils {
    public struct ContentType {
        public static let pgpKeys = "application/pgp-keys"
        public static let pgpEncrypted = "application/pgp-encrypted"
        public static let html = "text/html"
        public static let plainText = "text/plain"
        public static let multipartMixed = "multipart/mixed"
        public static let multipartEncrypted = "multipart/encrypted"
        public static let multipartRelated = "multipart/related"
        public static let multipartAlternative = "multipart/alternative"

        public struct Parameter {
            public static let pgpEncrypted = "application/pgp-encrypted"
        }
    }
}

