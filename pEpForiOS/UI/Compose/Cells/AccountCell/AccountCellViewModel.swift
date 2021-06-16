//
//  AccountCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

protocol AccountCellViewModelResultDelegate: class {
    func accountCellViewModel(_ vm: AccountCellViewModel, accountChangedTo account: Account)
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

    private var selectedAccount: Account?
    public var displayAccount: String? {
        return selectedAccount?.user.address
    }

    init(resultDelegate: AccountCellViewModelResultDelegate?, initialAccount: Account? = nil) {
        self.resultDelegate = resultDelegate
        selectedAccount = initialAccount
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
        resultDelegate?.accountCellViewModel(self, accountChangedTo: account)
    }
}
