//
//  SubjectCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

final class SubjectCell: TextViewContainingTableViewCell {

    static let reuseId = "SubjectCell"

    @IBOutlet weak var subjectLabel: UILabel!

    private var viewModel: SubjectCellViewModel?

    public func setup(with viewModel: SubjectCellViewModel) {

        self.viewModel = viewModel
        setStyle()
        textView.text = viewModel.content
    }

    private func setStyle() {
        textView.font = UIFont.planckFont(style: .footnote, weight: .regular)
        subjectLabel.font = UIFont.planckFont(style: .footnote, weight: .regular)
    }
}

// MARK: - UITextViewDelegate

extension SubjectCell {

    func textViewDidChange(_ textView: UITextView) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleTextChanged(to: textView.text)
    }

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return true
        }

       return vm.shouldChangeText(to: text)
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
