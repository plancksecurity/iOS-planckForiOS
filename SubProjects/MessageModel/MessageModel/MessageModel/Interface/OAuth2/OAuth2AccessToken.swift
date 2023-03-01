//
//  OAuth2AccessToken.swift
//  pEp
//
//  Created by Dirk Zimmermann on 12.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import AppAuth

/**
 Result of an OAuth2 authorization request. Persist this, and use it anytime you need
 fresh tokens.
 */
public class OAuth2AccessToken: NSObject, NSSecureCoding {
    public let keyChainID: String
    let authState: OIDAuthState

    public init(authState: OIDAuthState, keyChainID: String) {
        self.authState = authState
        self.keyChainID = keyChainID
        super.init()
        listenToStateChanges()
    }

    // MARK: NSSecureCoding

    private let kAuthState = "authState"
    private let kKeyChainID = "keyChainID"

    public static var supportsSecureCoding: Bool = true

    public required init?(coder aDecoder: NSCoder) {
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
    func decode(jwtToken jwt: String) -> [String: Any] {
      let segments = jwt.components(separatedBy: ".")
      return decodeJWTPart(segments[1]) ?? [:]
    }

    func base64UrlDecode(_ value: String) -> Data? {
      var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

      let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
      let requiredLength = 4 * ceil(length / 4.0)
      let paddingLength = requiredLength - length
      if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 = base64 + padding
      }
      return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }

    func decodeJWTPart(_ value: String) -> [String: Any]? {
      guard let bodyData = base64UrlDecode(value),
        let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
          return nil
      }
      return payload
    }
    
    public func getEmail() -> String {
        if let idToken = self.authState.lastTokenResponse?.idToken {
            let jwt = decode(jwtToken: idToken)
            if let email = jwt["email"] as? String {
                return email;
            }

        }
        return "";
    }
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(keyChainID, forKey: kKeyChainID)
        aCoder.encode(authState, forKey: kAuthState)
    }

    func listenToStateChanges() {
        authState.stateChangeDelegate = self
    }
}

extension OAuth2AccessToken: OAuth2AccessTokenProtocol {
    public func performAction(
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
    public func didChange(_ state: OIDAuthState) {
        let payload = persistIntoString()
        KeyChain.updateCreateOrDelete(password: payload, forKey: keyChainID)
    }
}
