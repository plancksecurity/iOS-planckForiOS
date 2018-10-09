//
//  SubjectCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol SubjectCellDelegate: class {
    func subjectCellSizeChanged()
}

class SubjectCell: TextViewContainingTableViewCell {
    static let reuseId = "SubjectCell"
    var viewModel: SubjectCellViewModel?

    override func awakeFromNib() {
        textView.delegate = self
    }

    public func setup(with viewModel: SubjectCellViewModel) {
        self.viewModel = viewModel
        self.textView.attributedText = viewModel.content
    }
}

extension SubjectCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
////        textView.sizeToFit()
//        sizeToFit()
//        print("textViewDidChange")
        viewModel?.handleTextChanged(to: textView.attributedText)
    }
}
