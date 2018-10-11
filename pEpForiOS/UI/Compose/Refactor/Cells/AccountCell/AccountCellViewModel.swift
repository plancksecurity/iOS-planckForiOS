//
//  AccountCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol AccountCellViewModelResultDelegate: class {
    func accountChanged(newAccount: Account)
}

protocol AccountCellViewModelDelegate: class {
    func accountChanged(newValue: String)
}

class AccountCellViewModel: CellViewModel {
    public let title = NSLocalizedString("From:",
                                         comment:
        "Title of account picker when composing a message")
    public var content: String?

    weak public var resultDelegate: AccountCellViewModelResultDelegate?
    weak public var delegate: AccountCellViewModelDelegate?

    public private(set) var selectedAccount: Account?

    init(resultDelegate: AccountCellViewModelResultDelegate) {
        self.resultDelegate = resultDelegate
    }

    public var accountPickerViewModel: AccountPickerViewModel {
        return AccountPickerViewModel(resultDelegate: self)
    }
}

// MARK: - AccountPickerViewModelResultDelegate

extension AccountCellViewModel: AccountPickerViewModelResultDelegate {
    func accountPickerViewModel(_ vm: AccountPickerViewModel, didSelect account: Account) {
        selectedAccount = account
        delegate?.accountChanged(newValue: account.user.address)
        resultDelegate?.accountChanged(newAccount: account)
    }
}
