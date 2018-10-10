//
//  SubjectCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class SubjectCell: TextViewContainingTableViewCell {
    static let reuseId = "SubjectCell"
    var viewModel: SubjectCellViewModel?

    public func setup(with viewModel: SubjectCellViewModel) {
        self.viewModel = viewModel
        if viewModel.content != nil {
            self.textView.text = viewModel.content
        }
    }
}

// MARK: - UITextViewDelegate

extension SubjectCell {
    func textViewDidChange(_ textView: UITextView) {
        viewModel?.handleTextChanged(to: textView.text)
    }
}
