//
//  KeyImportCell.swift
//  pEp
//
//  Created by Hussein on 05/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


protocol KeyImportAccountCell {
    var address : String { get }

    func getWizardViewModel() -> AutoWizardStepsViewModel

}

class KeyImportAccountCellViewModel {
    var account: Account
    let keyImportService: KeyImportServiceProtocol

    init(account: Account, keyImportService: KeyImportServiceProtocol) {
        self.account = account
        self.keyImportService = keyImportService
    }
}

// MARK: - KeyImportAccountCell
extension KeyImportAccountCellViewModel : KeyImportAccountCell {
    var address: String {
        get {
            return account.user.address
        }
    }

    func getWizardViewModel() -> AutoWizardStepsViewModel {
        return AutoWizardStepsViewModel(keyImportService: keyImportService, account: account)
    }

}
