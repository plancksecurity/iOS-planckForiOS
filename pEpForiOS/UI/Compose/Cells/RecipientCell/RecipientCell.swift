//
//  RecipientCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

final class RecipientCell: TextViewContainingTableViewCell {
    static let reuseId = "RecipientCell"

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var addButton: UIButton!

    private weak var viewModel: RecipientCellViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setFonts()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipientTextView?.text = ""
    }

    public func setup(with viewModel: RecipientCellViewModel) {
        self.viewModel = viewModel
        self.viewModel?.recipientCellViewModelDelegate = self
        recipientTextView?.viewModel = self.viewModel?.recipientTextViewModel()
        title.text = viewModel.type.localizedTitle()
        recipientTextView?.setInitialText()
    }

    private func setFonts() {
        title.font = UIFont.pepFont(style: .footnote,
                                    weight: .regular)
        recipientTextView?.font = UIFont.pepFont(style: .footnote,
                                                 weight: .regular)
    }

    private var recipientTextView: RecipientTextView? {
        return textView as? RecipientTextView
    }

    @IBAction func addContactTapped(_ sender: Any) {
        viewModel?.addContactAction()
    }

}

extension RecipientCell: RecipientCellViewModelDelegate {
    func focusChanged() {
        if addButton.isEnabled != textView.isFirstResponder {
            let hasFocus = textView.isFirstResponder
            addButton.isEnabled = hasFocus
            addButton.alpha = hasFocus ? 1 : 0
        }
    }
}
