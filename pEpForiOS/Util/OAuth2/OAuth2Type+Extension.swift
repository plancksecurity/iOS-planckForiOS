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
                oauth2Type: .google,
                scopes: ["https://mail.google.com/"],
                clientIDKey: "OAUTH2_GMAIL_CLIENT_ID",
                redirectURLSchemeKey: "OAUTH2_GMAIL_REDIRECT_URL_SCHEME")
        case .o365:
            return OAuth2Configuration(
                oauth2Type: .o365,
                scopes: [
                    "https://outlook.office.com/IMAP.AccessAsUser.All",
                    "https://outlook.office.com/SMTP.Send"],
                clientIDKey: "OAUTH2_O365_CLIENT_ID",
                redirectURLSchemeKey: "OAUTH2_O365_REDIRECT_URL_SCHEME")
        }
    }

    func configurationOID() -> OIDServiceConfiguration {
        switch self {
        case .google:
            return OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
                tokenEndpoint: URL(string: "https://www.googleapis.com/oauth2/v4/token")!)
        case .o365:
            return OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize")!,
                tokenEndpoint: URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token")!)
        }
    }
}
