//
//  OAuth2AccessToken.swift
//  pEp
//
//  Created by Dirk Zimmermann on 12.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Result of an OAuth2 authorization request. Persist this, and invoke it anytime you need
 fresh tokens.
 */
class OAuth2AccessToken: NSObject, NSSecureCoding, OAuth2AccessTokenProtocol {
    let authState: OIDAuthState

    init(authState: OIDAuthState) {
        self.authState = authState
    }

    func performAction(
        freshTokensBlock: @escaping (_ error: Error?, _ accessToken: String?) -> Void) {
        authState.performAction() { accessToken, idToken, error in
            freshTokensBlock(error, accessToken)
        }
    }

    // MARK: NSSecureCoding

    private let kAuthState = "authState"

    static var supportsSecureCoding: Bool = true

    required init?(coder aDecoder: NSCoder) {
        guard let authState = aDecoder.decodeObject(
            of: OIDAuthState.self, forKey: kAuthState) else {
                return nil
        }
        self.authState = authState
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(authState, forKey: kAuthState)
    }

    /**
     Persists itself into a string.
     */
    func persistIntoString() -> String {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        return data.base64EncodedString()
    }

    static func from(base64Encoded: String) -> OAuth2AccessTokenProtocol? {
        guard let data = Data(base64Encoded: base64Encoded) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? OAuth2AccessToken
    }
}
