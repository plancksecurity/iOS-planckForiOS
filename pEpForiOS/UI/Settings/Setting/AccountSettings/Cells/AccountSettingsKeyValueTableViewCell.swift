//
//  AccountSettingsKeyValueTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 27/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Cell that displays a title and a value.
final class AccountSettingsKeyValueTableViewCell: UITableViewCell {

    static let identifier = "KeyValueTableViewCell"
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueTextfield: UITextField!

    @IBOutlet private weak var stackView: UIStackView!

    /// Configure the cell according to the current trait collection
    public func configure(with row : AccountSettingsViewModel2.DisplayRow? = nil) {
        let contentSize = traitCollection.preferredContentSizeCategory
        stackView.axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        stackView.spacing = contentSize.isAccessibilityCategory ? 10.0 : 5.0

        guard let row = row else {
            //This is a valid case
            return
        }
        keyLabel.text = row.title
        valueTextfield.text = row.text
        valueTextfield.isSecureTextEntry = row.type == .password
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
        keyLabel.font = UIFont.pepFont(style: .body, weight: .regular)
        valueTextfield.font = UIFont.pepFont(style: .body, weight: .regular)
    }
}
