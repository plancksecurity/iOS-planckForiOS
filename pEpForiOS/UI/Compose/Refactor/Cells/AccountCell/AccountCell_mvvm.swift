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
    var viewModel: AccountCellViewModel?

    public func setup(with viewModel: AccountCellViewModel) {
        self.viewModel = viewModel
        if viewModel.content != nil {
            self.textView.text = viewModel.content
        }
    }
}

// MARK: - UITextViewDelegate

extension AccountCell_mvvm {
    func textViewDidChange(_ textView: UITextView) {
        //IOS-1369. TODO
//        viewModel?.handleTextChanged(to: textView.text)
    }
}
