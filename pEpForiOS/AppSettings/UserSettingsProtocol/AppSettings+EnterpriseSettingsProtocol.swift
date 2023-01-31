//
//  AppSettings+EnterpriseSettingsProtocol.swift
//  pEpForiOS
//
//  Created by Martín Brude on 19/1/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation

extension AppSettings: EnterpriseSettingsProtocol {

    public var isEnterprise: Bool {
        get {
            return EnterpriseUtil.isEnterprise()
        }
    }
}

