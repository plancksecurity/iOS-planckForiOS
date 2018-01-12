//
//  OAuth2Configuration.swift
//  pEp
//
//  Created by Dirk Zimmermann on 11.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

struct OAuth2Configuration: OAuth2ConfigurationProtocol {
    let oauth2Type: OAuth2Type
    let scopes: [String]
    let clientID: String
    let redirectURL: URL

    init?(oauth2Type: OAuth2Type, scopes: [String], clientIDKey: String, redirectURLKey: String) {
        self.oauth2Type = oauth2Type
        self.scopes = scopes

        guard let settings = Bundle.main.infoDictionary else {
            return nil
        }
        guard let clientID = settings[clientIDKey] as? String else {
            return nil
        }
        guard let redirectURLScheme = settings[redirectURLKey] as? String else {
            return nil
        }
        guard let redirectURL = URL(string: "\(redirectURLScheme):/\(Date().hashValue)") else {
            return nil
        }

        self.clientID = clientID
        self.redirectURL = redirectURL
    }
}
