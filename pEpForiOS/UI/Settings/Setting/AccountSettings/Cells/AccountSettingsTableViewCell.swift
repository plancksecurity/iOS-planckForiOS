//
//  AccountSettingsKeyValueTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 27/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import PlanckToolbox
import UIKit

/// Cell that displays a title and a value.
final class AccountSettingsTableViewCell: UITableViewCell {
    static let identifier = "KeyValueTableViewCell"
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueTextfield: ConfigurableCaretTextField!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private var valueFieldWidthConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        keyLabel.font = UIFont.planckFont(style: .body, weight: .regular)
        valueTextfield.font = UIFont.planckFont(style: .body, weight: .regular)
    }

    /// Configure the cell with the appropiate content from the row according to the current trait collection
    /// Title, textfield, keyboard and layout in general are configured.
    /// - Parameters:
    ///   - displayRow: The row to configurate the cell
    ///   - traitCollection: The current trait collection.
    public func configure(with displayRow: AccountSettingsViewModel.DisplayRow? = nil, for traitCollection : UITraitCollection? = nil) {
        guard let traitCollection = traitCollection else {
            return
        }
        let contentSize = traitCollection.preferredContentSizeCategory
        stackView.axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        stackView.spacing = contentSize.isAccessibilityCategory ? 10.0 : 5.0
        valueFieldWidthConstraint.isActive = stackView.axis == .horizontal

        guard let row = displayRow else {
            Log.shared.errorAndCrash("Without row the cell can not be configured")
            return
        }
        keyLabel.text = row.title
        valueTextfield.autocorrectionType = .no
        valueTextfield.text = row.text
        valueTextfield.isSecureTextEntry = row.type == .password
        valueTextfield.shouldShowCaret = row.shouldShowCaret
        valueTextfield.shouldSelect = row.shouldSelect
        accessoryType = .none
        selectionStyle = .none
        stackView.spacing = 0

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

    /// Configure the cell with the appropiate content from the row according to the current trait collection
    /// Title, textfield, keyboard and layout in general are configured.
    /// - Parameters:
    ///   - actionRow: The row to configurate the cell
    ///   - traitCollection: The current trait collection.
    public func configure(with actionRow : AccountSettingsViewModel.ActionRow? = nil,
                          for traitCollection : UITraitCollection? = nil) {
        guard let traitCollection = traitCollection else {
            return
        }
        let contentSize = traitCollection.preferredContentSizeCategory
        stackView.axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        stackView.spacing = contentSize.isAccessibilityCategory ? 10.0 : 5.0
        guard let row = actionRow else {
            Log.shared.errorAndCrash("Without row the cell can not be configured")
            return
        }

        keyLabel.text = row.title
        valueTextfield.text = row.text
        valueTextfield.isEnabled = false
        valueTextfield.shouldShowCaret = false
        valueTextfield.shouldSelect = false
        accessoryType = .disclosureIndicator
        selectionStyle = .default
    }
}
