//
//  OAuth2AccessToken.swift
//  pEp
//
//  Created by Dirk Zimmermann on 12.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Result of an OAuth2 authorization request. Persist this, and use it anytime you need
 fresh tokens.
 */
class OAuth2AccessToken: NSObject, NSSecureCoding {
    let keyChainID: String
    let authState: OIDAuthState

    init(authState: OIDAuthState, keyChainID: String) {
        self.authState = authState
        self.keyChainID = keyChainID
        super.init()
        listenToStateChanges()
    }

    // MARK: NSSecureCoding

    private let kAuthState = "authState"
    private let kKeyChainID = "keyChainID"

    static var supportsSecureCoding: Bool = true

    required init?(coder aDecoder: NSCoder) {
        guard let authState = aDecoder.decodeObject(
            of: OIDAuthState.self, forKey: kAuthState) else {
                return nil
        }
        self.authState = authState

        guard let keyChainID = aDecoder.decodeObject(
            of: NSString.self, forKey: kKeyChainID) else {
                return nil
        }
        self.keyChainID = keyChainID as String

        super.init()
        listenToStateChanges()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(keyChainID, forKey: kKeyChainID)
        aCoder.encode(authState, forKey: kAuthState)
    }

    func listenToStateChanges() {
        authState.stateChangeDelegate = self
    }
}

extension OAuth2AccessToken: OAuth2AccessTokenProtocol {
    func performAction(
        freshTokensBlock: @escaping (_ error: Error?, _ accessToken: String?) -> Void) {
        authState.performAction() { accessToken, idToken, error in
            freshTokensBlock(error, accessToken)
        }
    }

    // MARK: Own persistence code

    func persistIntoString() -> String {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        return data.base64EncodedString()
    }
}

extension OAuth2AccessToken: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        // TODO: Have to persist the change
        Log.shared.info(component: #function, content: "should persist")
    }
}
