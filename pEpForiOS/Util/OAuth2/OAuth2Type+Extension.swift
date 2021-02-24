//
//  OAuth2Type+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import AppAuth

extension OAuth2Type {
    func oauth2Config() -> OAuth2ConfigurationProtocol? {
        switch self {
        case .google:
            return OAuth2Configuration(
                oauth2Type: .google, scopes: ["https://mail.google.com/"],
                clientIDKey: "OAUTH2_GMAIL_CLIENT_ID",
                redirectURLSchemeKey: "OAUTH2_GMAIL_REDIRECT_URL_SCHEME")
        case .yahoo:
            return OAuth2Configuration(
                oauth2Type: .yahoo, scopes: ["openid"],
                clientIDKey: "OAUTH2_YAHOO_CLIENT_ID",
                clientSecretKey: "OAUTH2_YAHOO_CLIENT_SECRET",
                redirectURLKey: "OAUTH2_YAHOO_REDIRECT_URL")
        }
    }

    func configurationOID() -> OIDServiceConfiguration {
        switch self {
        case .google:
            return OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
                tokenEndpoint: URL(string: "https://www.googleapis.com/oauth2/v4/token")!)
        case .yahoo:
            return OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "https://api.login.yahoo.com/oauth2/request_auth")!,
                tokenEndpoint: URL(string: "https://api.login.yahoo.com/oauth2/get_token")!)
        }
    }
}
