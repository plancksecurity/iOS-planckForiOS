//
//  OIDAuthState+pEp.swift
//  pEp
//
//  Created by Sascha Bacardit on 3/3/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import AppAuth

extension OIDAuthState {

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
        if let idToken = lastTokenResponse?.idToken {
            let jwt = decode(jwtToken: idToken)
            if let email = jwt["email"] as? String {
                return email;
            }

        }
        return "";
    }
    public func getName() -> String {
        if let idToken = lastTokenResponse?.idToken {
            let jwt = decode(jwtToken: idToken)
            if let email = jwt["name"] as? String {
                return email;
            }

        }
        return "";

    }

}
