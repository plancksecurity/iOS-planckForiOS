//
//  CreditsViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

class CreditsViewModel {
    private var appSettings: AppSettingsProtocol

    init(appSettings: AppSettingsProtocol? = nil) {
        self.appSettings = appSettings ?? AppSettings.shared
    }

    public func handleVerboseLoggingSwitchChange(newValue: Bool) {
        appSettings.verboseLogginEnabled = newValue
    }
}
