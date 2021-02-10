//
//  AccountCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

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
        setupPickerView()
        guard let accountToShow = viewModel.displayAccount,
            let pickerPosition = viewModel.accountPickerViewModel.row(at: accountToShow) else {
            return
        }
        self.picker?.selectRow(pickerPosition, inComponent: 0, animated: true)
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
