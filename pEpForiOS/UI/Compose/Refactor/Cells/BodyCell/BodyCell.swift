//
//  BodyCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class BodyCell: TextViewContainingTableViewCell {
    static let reuseId = "BodyCell"

    var viewModel: BodyCellViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    public func setup(with viewModel: BodyCellViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - BodyCellViewModelDelegate

extension BodyCell: BodyCellViewModelDelegate {
    //IOS-1369:
}

// MARK: - UITextViewDelegate

extension BodyCell {
    public func textViewDidBeginEditing(_ textView: UITextView) {
//        viewModel?.maxTextattachmentWidth = bounds.width
        //IOS-1369: scroll?
    }

    public func textViewDidChange(_ textView: UITextView) {
        //IOS-1369: scroll?
        viewModel?.handleTextChange(newText: textView.text)
    }

    /*
     //IOS-1369: Next !!

     */


    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
        //IOS-21369:
//        guard let vm = viewModel else {
//            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
//            return true
//        }
        return true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
//        viewModel?.handleDidEndEditing(range: textView.selectedRange, of: textView.attributedText)
    }

    func textView(_ textView: UITextView,
                  shouldInteractWith textAttachment: NSTextAttachment,
                  in characterRange: NSRange) -> Bool {
        //IOS-21369:
//        guard let vm = viewModel else {
//            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
//            return true
//        }
//        return vm.shouldInteract(WithTextAttachment: textAttachment)
        return true
    }
}
