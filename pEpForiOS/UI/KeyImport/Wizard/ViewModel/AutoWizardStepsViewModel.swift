//
//  AutoWizardStepsViewModel.swift
//  pEp
//
//  Created by Hussein on 03/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


class AutoWizardStepsViewModel {
    private let keyImportService: KeyImportServiceProtocol
    private let account: Account
    private var keyImportWizzard: KeyImportWizzard

    
    init(account: Account, keyImportService: KeyImportServiceProtocol) {
        self.keyImportService = keyImportService
        self.account = account
        self.keyImportWizzard = KeyImportWizzard(keyImportService: keyImportService,
                                                account: account)
    }
    
}
