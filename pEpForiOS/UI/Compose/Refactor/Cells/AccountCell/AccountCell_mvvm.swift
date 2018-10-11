//
//  AccountCell_mvvm.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

//IOS-1369: rename and get rid of the other
class AccountCell_mvvm: TextViewContainingTableViewCell {
    static let reuseId = "AccountCell_mvvm"
    private var viewModel: AccountCellViewModel? {
        didSet {
            viewModel?.delegate = self
            textView.text = viewModel?.displayAccount

        }
    }
    private var picker: AccountPickerView?

    public func setup(with viewModel: AccountCellViewModel) {
        self.viewModel = viewModel
        if viewModel.content != nil {
            self.textView.text = viewModel.content
        }
        setupPickerView()
    }

    private func setupPickerView() {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return
        }
        picker = AccountPickerView()
        picker?.viewModel = viewModel.accountPickerViewModel
        textView.inputView = picker
        picker?.reloadAllComponents()
    }
}

// MARK: - AccountCellViewModelDelegate

extension AccountCell_mvvm: AccountCellViewModelDelegate {
    func accountChanged(newValue: String) {
        textView.text = newValue
    }
}
