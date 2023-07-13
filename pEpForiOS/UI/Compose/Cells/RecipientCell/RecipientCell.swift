//
//  RecipientCell.swift
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

final class RecipientCell: TextViewContainingTableViewCell {
    static let reuseId = "RecipientCell"

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var addButton: UIButton!

    private weak var viewModel: RecipientCellViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setFonts()
        addButton.tintColor = UITraitCollection.current.userInterfaceStyle == .dark ? .primaryDarkMode : .primaryLightMode
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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.addContactAction()
    }

}

extension RecipientCell: RecipientCellViewModelDelegate {

    func focusChanged() {
        if addButton.isEnabled != textView.isFirstResponder {
            let hasFocus = textView.isFirstResponder
            addButton.isEnabled = hasFocus
            addButton.alpha = hasFocus ? 1 : 0
            if !hasFocus {
                guard let vm = viewModel else {
                    Log.shared.errorAndCrash("VM not found")
                    return
                }
                vm.handleFocusChanged()
            }
        }
    }
}
