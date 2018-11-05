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
    func subjectCellViewModel(_ subjectCellViewModel: SubjectCellViewModel,
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

    // MARK: First Baseline Alignment Workaround

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = firstBaselineAlingIssueWorkaroundRemoved(text: textView.text)
    }

    /// Out auto-layout is based on UIStackView's "First Baseline" alignment, which does not what
    /// we are expecting if the textview's text is empty. As a workaround we are setting the
    /// initital text to " " and remove it on text change.
    private func firstBaselineAlingIssueWorkaroundRemoved(text: String) -> String {
        if text.hasPrefix(" ") {
            return String(text.dropFirst())
        } else {
            return text
        }
    }
}
