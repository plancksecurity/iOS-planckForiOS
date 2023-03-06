//
//  OIDAuthState+pEp.swift
//  pEp
//
//  Created by Sascha Bacardit on 3/3/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import AppAuth
// Expands OIDAuthState to parse JWTokens, this allows any attempt (with properly set scoping) at OAuth2 to carry values for Email and Name fields amongst others.
/**
 Expands OIDAuthState to parse JWTokens, this allows any attempt (with properly set scoping) at OAuth2 to carry values for Email and Name fields amongst others.
 For the sake of simplicity, for now only Email and Name (which can be nil, if none is found)
 */

extension OIDAuthState {
    /// Depending on `OIDAuthState.getField`,
    /// returns the value for the field 'email' of the JWToken, or nil should it not exist.
    public func getEmail() -> String? {
        return getField(fieldName: "email");
    }
    /// Depending on `OIDAuthState.getField`,
    /// returns the value for the field 'email' of the JWToken, or nil should it not exist.
    public func getName() -> String? {
        return getField(fieldName: "name");
    }

}

//MARK: - Private
extension OIDAuthState {
    /// Depending on `OIDAuthState.decode`,
    /// returns the value for a field of the latest JWToken, or nil should it not exist.
    /// - Parameters:
    ///   - fieldName: name of the JWToken field
    private func getField(fieldName: String) -> String? {
        guard let idToken = lastTokenResponse?.idToken else {
            return nil
        }
        let jwt = decode(jwtToken: idToken)
        guard let field = jwt[fieldName] as? String else {
            return nil
        }
        return field
    }
    /// Depending on `OIDAuthState.base64UrlDecode` and `OIDAuthState.decodeJWTPart`
    /// decodes the JWToken into a hash of values.
    /// - Parameters:
    ///   - jwtToken: the latest JWToken
    private func decode(jwtToken jwt: String) -> [String: Any] {
        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    }

    private func base64UrlDecode(_ value: String) -> Data? {
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

    private func decodeJWTPart(_ value: String) -> [String: Any]? {
      guard let bodyData = base64UrlDecode(value),
        let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
          return nil
      }
      return payload
    }
}
