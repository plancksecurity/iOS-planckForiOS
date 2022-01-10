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
    let clientSecret: String?

    init?(
        oauth2Type: OAuth2Type, scopes: [String], clientID: String, clientSecret: String? = nil,
        redirectURL: URL) {
        self.oauth2Type = oauth2Type
        self.scopes = scopes
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURL = redirectURL
    }

    init?(
        oauth2Type: OAuth2Type, scopes: [String],
        clientIDKey: String,
        clientSecretKey: String? = nil,
        redirectURL: URL) {
        guard let settings = Bundle.main.infoDictionary else {
            return nil
        }
        guard let clientID = settings[clientIDKey] as? String else {
            return nil
        }

        var clientSecret: String? = nil
        if let theKey = clientSecretKey,
            let theClientSecret = settings[theKey] as? String {
            clientSecret = theClientSecret
        }

        self.init(oauth2Type: oauth2Type, scopes: scopes, clientID: clientID,
                  clientSecret: clientSecret, redirectURL: redirectURL)
    }

    init?(
        oauth2Type: OAuth2Type,
        scopes: [String],
        clientIDKey: String,
        clientSecretKey: String? = nil,
        redirectURLSchemeKey: String) {
        guard let settings = Bundle.main.infoDictionary else {
            return nil
        }
        guard let clientID = settings[clientIDKey] as? String else {
            return nil
        }
        guard let redirectURLScheme = settings[redirectURLSchemeKey] as? String else {
            return nil
        }

        guard let redirectURL = URL(
            string: "\(redirectURLScheme):/oauth2\(OAuth2Configuration.createTokenURLParamString())") else {
            return nil
        }

        var clientSecret: String? = nil
        if let theKey = clientSecretKey,
            let theClientSecret = settings[theKey] as? String {
            clientSecret = theClientSecret
        }

        self.init(oauth2Type: oauth2Type, scopes: scopes, clientID: clientID,
                  clientSecret: clientSecret, redirectURL: redirectURL)
    }

    init?(
        oauth2Type: OAuth2Type,
        scopes: [String],
        clientIDKey: String,
        clientSecretKey: String? = nil,
        redirectURLKey: String) {
        guard let settings = Bundle.main.infoDictionary else {
            return nil
        }
        guard let clientID = settings[clientIDKey] as? String else {
            return nil
        }
        guard let redirectURLBase = settings[redirectURLKey] as? String else {
            return nil
        }
        guard let redirectURL = URL(
            string: "\(redirectURLBase)\(OAuth2Configuration.createTokenURLParamString())") else {
                return nil
        }

        var clientSecret: String? = nil
        if let theKey = clientSecretKey,
            let theClientSecret = settings[theKey] as? String {
            clientSecret = theClientSecret
        }

        self.init(oauth2Type: oauth2Type, scopes: scopes, clientID: clientID,
                  clientSecret: clientSecret, redirectURL: redirectURL)
    }

    static func createTokenURLParamString() -> String {
        return "?token=\(createToken())"
    }

    static func createToken() -> String {
        return "\(Date().timeIntervalSinceReferenceDate)"
    }
}
