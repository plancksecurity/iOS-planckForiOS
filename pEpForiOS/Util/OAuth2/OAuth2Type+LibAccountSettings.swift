//
//  OAuth2Type+LibAccountSettings.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension OAuth2Type {
    init?(accountSettings: AccountSettingsProtocol?) {
        guard let ac = accountSettings else {
            return nil
        }
        if let provider = ac.providerID {
            if provider == AccountSettingsProviderIDGmail {
                self = .google
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
