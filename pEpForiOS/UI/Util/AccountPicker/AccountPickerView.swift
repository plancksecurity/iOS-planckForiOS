//
//  AccountPickerView.swift
//  pEp
//
//  Created by Andreas Buff on 10.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class AccountPickerView: UIPickerView {
    private var viewModel = AccountPickerViewModel()

    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
    }
}

extension AccountPickerView: UIPickerViewDelegate {
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

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.handleUserSelected(row: row)
    }
}
