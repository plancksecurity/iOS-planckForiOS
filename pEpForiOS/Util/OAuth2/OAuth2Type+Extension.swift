//
//  OAuth2Type+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension OAuth2Type {
    func oauth2Config() -> OAuth2ConfigurationProtocol? {
        switch self {
        case .google:
            return OAuth2Configuration(
                oauth2Type: .google, scopes: ["https://mail.google.com/"],
                clientIDKey: "OAUTH2_GMAIL_CLIENT_ID",
                redirectURLKey: "OAUTH2_GMAIL_REDIRECT_URL_SCHEME")
        case .yahoo:
            return OAuth2Configuration(
                oauth2Type: .yahoo, scopes: ["openid"],
                clientIDKey: "OAUTH2_YAHOO_CLIENT_ID",
                clientSecretKey: "OAUTH2_YAHOO_CLIENT_SECRET",
                redirectURL: URL(string: "oob")!)
        }
    }
}
