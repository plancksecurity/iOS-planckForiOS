//
//  RecipientCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientCell: TextViewContainingTableViewCell {
    static let reuseId = "RecipientCell"
    @IBOutlet weak var title: UILabel!
    var viewModel: RecipientCellViewModel?
    private var recipientTextView: RecipientTextView? {
        return textView as? RecipientTextView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setFonts()
    }

    public func setup(with viewModel: RecipientCellViewModel) {
        self.viewModel = viewModel
        recipientTextView?.viewModel = self.viewModel?.recipientTextViewModel()
        title.text = viewModel.type.localizedTitle()
        recipientTextView?.setInitialText()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipientTextView?.text = ""
    }

    private func setFonts() {
        title.font = UIFont.pepFont(style: .footnote, weight: .regular)
        recipientTextView?.font = UIFont.pepFont(style: .footnote, weight: .regular)
    }
}
