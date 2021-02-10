//
//  AccountPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 10.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

protocol AccountPickerViewModelResultDelegate: class {
    func accountPickerViewModel(_ vm: AccountPickerViewModel, didSelect account: Account)
}

class AccountPickerViewModel {
    private let accounts = Account.all()

    lazy public private(set) var content = accounts.map { $0.user.address }
    public var numAccounts: Int {
        return accounts.count
    }

    public weak var resultDelegate: AccountPickerViewModelResultDelegate?

    init(resultDelegate: AccountPickerViewModelResultDelegate? = nil) {
        self.resultDelegate = resultDelegate
    }

    public func account(at row: Int) -> String {
        return content[row]
    }

    public func row(at account: String) -> Int? {
        return content.firstIndex(of: account)
    }

    public func handleUserSelected(row: Int) {
        resultDelegate?.accountPickerViewModel(self, didSelect: accounts[row])
    }
}
