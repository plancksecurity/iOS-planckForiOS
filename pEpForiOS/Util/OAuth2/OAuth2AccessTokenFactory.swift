//
//  OAuth2AccessTokenFactory.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Can instantiate OAuth2AccessTokenProtocol objects that were persisted into a string.
 Gives implementation independence of the actual class implementing OAuth2AccessTokenProtocol.
 */
struct OAuth2AccessTokenFactory {
    static func from(base64Encoded: String) -> OAuth2AccessTokenProtocol? {
        guard let data = Data(base64Encoded: base64Encoded) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? OAuth2AccessToken
    }
}
