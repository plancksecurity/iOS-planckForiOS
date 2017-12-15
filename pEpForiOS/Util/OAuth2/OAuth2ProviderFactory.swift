//
//  OAuth2ProviderFactory.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class OAuth2ProviderFactory {
    func oauth2Provider() -> OAuth2ProviderProtocol {
        return OAuth2Provider()
    }
}
