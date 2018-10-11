//
//  AccountPickerView.swift
//  pEp
//
//  Created by Andreas Buff on 10.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class AccountPickerView: UIPickerView {
    public var viewModel = AccountPickerViewModel() {
        didSet {
            dataSource = self
            delegate = self
        }
    }
}

// MARK: - UIPickerViewDelegate

extension AccountPickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.handleUserSelected(row: row)
    }
}

// MARK: - UIPickerViewDataSource

extension AccountPickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.numAccounts
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return viewModel.account(at: row)
    }
}
