//
//  OAuth2Config.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

enum OAuth2Config {
    case google

    func configuration() -> OIDServiceConfiguration {
        switch self {
        case .google:
            return OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
                tokenEndpoint: URL(string: "https://www.googleapis.com/oauth2/v4/token")!)
        }
    }
}
