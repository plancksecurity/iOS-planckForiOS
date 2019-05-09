//
//  AccountCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class AccountCell: TextViewContainingTableViewCell {
    static let reuseId = "AccountCell"

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
            Log.shared.errorAndCrash("No VM")
            return
        }
        picker = AccountPickerView()
        picker?.viewModel = viewModel.accountPickerViewModel
        textView.inputView = picker
        picker?.reloadAllComponents()
    }
}

// MARK: - AccountCellViewModelDelegate

extension AccountCell: AccountCellViewModelDelegate {
    func accountChanged(newValue: String) {
        textView.text = newValue
    }
}
