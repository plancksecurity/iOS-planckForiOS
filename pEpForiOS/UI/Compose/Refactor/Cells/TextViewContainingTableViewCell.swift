//
//  TextViewContainingTableViewCell.swift
//  pEp
//
//  Created by Andreas Buff on 08.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

//IOS-1369: move
protocol TextViewManagingViewModelProtocol {
    func handleTextDidChange(textView: NSAttributedString)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidBeginEditing textView: UITextView)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidChangeSelection textView: UITextView)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidEndEditing textView: UITextView)
}

protocol TextViewContainingTableViewCellProtocol {
    var textView: UITextView! { get set }
    var delegate: TextViewContainingTableViewCellDelegate? { get set }
}

protocol TextViewContainingTableViewCellDelegate: class {
    // MARK: - Forwarding UITextViewDelegate
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidChange textView: UITextView)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidBeginEditing textView: UITextView)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidChangeSelection textView: UITextView)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidEndEditing textView: UITextView)
}

class TextViewContainingTableViewCell: UITableViewCell, TextViewContainingTableViewCellProtocol {

    @IBOutlet weak public var textView: UITextView!
    weak var delegate: TextViewContainingTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        textView.delegate = self
    }
}

extension TextViewContainingTableViewCell: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        delegate?.textViewContainingTableViewCell(self, textViewDidChange: textView)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewContainingTableViewCell(self, textViewDidBeginEditing: textView)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textViewContainingTableViewCell(self, textViewDidChangeSelection: textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewContainingTableViewCell(self, textViewDidEndEditing: textView)
    }
}
