//
//  OAuth2ConfigurationProtocol+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension OAuth2ConfigurationProtocol {
    /**
     Determines `OAuth2ConfigurationProtocol` for a given email address, using
     LibAccountSettings, only uses fast local lookups.
     - Returns The oauth2 configuration the given email, or nil if none could be found.
     */
    static func from(emailAddress: String?) -> OAuth2ConfigurationProtocol? {
        return OAuth2Type(
            accountSettings: AccountSettings.quickLookUp(
                emailAddress: emailAddress))?.oauth2Config()
    }
}
