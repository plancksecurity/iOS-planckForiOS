//
//  AccountSettingsProtocol+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 26.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension AccountSettingsProtocol {
    /**
     Determines `AccountSettingsProtocol` for a given email address,
     only doing fast local lookups.
     */
    static func quickLookUp(emailAddress: String?) -> AccountSettingsProtocol? {
        if let theMail = emailAddress?.trimmedWhiteSpace() {
            let acSettings = AccountSettings(accountName: theMail, provider: nil,
                                             flags: AS_FLAG_USE_ANY_LOCAL, credentials: nil)

            // do a sync call, but this should only lookup local information, so not blocking
            acSettings.lookup()

            if let _ = AccountSettings.AccountSettingsError(accountSettings: acSettings) {
                return nil
            }

            return acSettings
        } else {
            return nil
        }
    }
}
