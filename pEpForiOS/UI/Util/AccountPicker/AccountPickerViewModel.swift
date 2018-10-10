//
//  AccountPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 10.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol AccountPickerViewModelResultDelegate: class {
    func SubjectCellViewModelDidChangeSubject(_ subjectCellViewModel: SubjectCellViewModel)
}

class AccountPickerViewModel {
    private let accounts = Account.all()

    lazy public private(set) var content = accounts.map { $0.user.address }
    public var numAccounts: Int {
        return content.count
    }

    public weak var resultDelegate: AccountPickerViewModelResultDelegate?

    init(resultDelegate: AccountPickerViewModelResultDelegate? = nil) {
        self.resultDelegate = resultDelegate
    }

    public func account(at row: Int) -> String {
        return content[row]
    }

    public func handleUserSelected(row: Int) {
        fatalError("unimplemented stub")
    }
}
