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
    var viewModel: SubjectCellViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    public func setup(with viewModel: SubjectCellViewModel) {
        self.viewModel = viewModel
        if viewModel.content != nil {
            self.textView.text = viewModel.content
        }
    }
}

// MARK: - SubjectCellViewModelDelegate

extension SubjectCell: SubjectCellViewModelDelegate {
    func subjectCellViewModelDelegate(_ subjectCellViewModelDelegate: SubjectCellViewModelDelegate,
                                      requireFirstResponder: Bool) {
        if requireFirstResponder {
            resignFirstResponder()
        }
    }
}

// MARK: - UITextViewDelegate

extension SubjectCell {
    func textViewDidChange(_ textView: UITextView) {
        viewModel?.handleTextChanged(to: textView.text)
    }

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
       return viewModel?.shouldChangeText(to: text) ?? true
    }
}
