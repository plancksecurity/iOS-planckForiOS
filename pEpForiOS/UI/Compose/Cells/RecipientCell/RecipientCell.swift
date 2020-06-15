//
//  RecipientCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol RecipientCellDelegate: class {
    func focusChanged()
}

final class RecipientCell: TextViewContainingTableViewCell {
    static let reuseId = "RecipientCell"

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var addContact: UIButton!

    var viewModel: RecipientCellViewModel?

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
        self.viewModel?.recipientCellDelegate = self
        recipientTextView?.viewModel = self.viewModel?.recipientTextViewModel()
        title.text = viewModel.type.localizedTitle()
        recipientTextView?.setInitialText()
    }

    private func setFonts() {
        title.font = UIFont.pepFont(style: .footnote, weight: .regular)
        recipientTextView?.font = UIFont.pepFont(style: .footnote, weight: .regular)
    }

    private var recipientTextView: RecipientTextView? {
        return textView as? RecipientTextView
    }

    @IBAction func addContactTapped(_ sender: Any) {
        viewModel?.addContactAction()
    }

}

extension RecipientCell: RecipientCellDelegate {
    func focusChanged() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(message: "viewModel is missing!")
            return
        }
        if !addContact.isHidden != vm.focused {
            addContact.isHidden = !vm.focused
        }
    }
}
