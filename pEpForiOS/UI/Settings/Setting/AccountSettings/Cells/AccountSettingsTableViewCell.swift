//
//  AccountSettingsKeyValueTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 27/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import UIKit

/// Cell that displays a title and a value.
final class AccountSettingsTableViewCell: UITableViewCell {
    static let identifier = "KeyValueTableViewCell"
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueTextfield: ConfigurableCaretTextField!
    @IBOutlet private weak var stackView: UIStackView!

    /// Configure the cell according to the current trait collection
    public func configure(with row : AccountSettingsViewModel.DisplayRow? = nil, for traitCollection : UITraitCollection? = nil) {
        guard let traitCollection = traitCollection else {
            //This is a valid case
            return
        }
        let contentSize = traitCollection.preferredContentSizeCategory
        stackView.axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        stackView.spacing = contentSize.isAccessibilityCategory ? 10.0 : 5.0

        guard let row = row else {
            Log.shared.errorAndCrash("Without row the cell can not be configured")
            return
        }
        keyLabel.text = row.title
        valueTextfield.autocorrectionType = .no
        valueTextfield.text = row.text
        valueTextfield.isSecureTextEntry = row.type == .password
        valueTextfield.shouldShowCaret = row.shouldShowCaret
        valueTextfield.shouldSelect = row.shouldSelect
        switch row.type {
        case .email:
            valueTextfield.isEnabled = false
        case .port:
            valueTextfield.keyboardType = .numberPad
        default:
            // Nothing to do.
            break;
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
        keyLabel.font = UIFont.pepFont(style: .body, weight: .regular)
        valueTextfield.font = UIFont.pepFont(style: .body, weight: .regular)
    }
}

