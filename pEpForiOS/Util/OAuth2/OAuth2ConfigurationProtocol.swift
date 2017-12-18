//
//  OAuth2ConfigurationProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol OAuth2ConfigurationProtocol {
    var oauth2Type: OAuth2Type { get }
    var clientID: String { get }
    var redirectURL: URL { get }
    var scopes: [String] { get }
}
