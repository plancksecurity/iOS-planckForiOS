//
//  OAuth2Configurator.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class OAuth2Configurator {
    func oauth2ConfigFor(oauth2Type: OAuth2Type) -> OAuth2ConfigurationProtocol? {
        switch oauth2Type {
        case .google:
            return OAuth2Configuration(
                oauth2Type: .google, scopes: ["https://mail.google.com/"],
                clientIDKey: "OAUTH2_GMAIL_CLIENT_ID",
                redirectURLKey: "OAUTH2_GMAIL_REDIRECT_URL_SCHEME")
        }
    }
}
