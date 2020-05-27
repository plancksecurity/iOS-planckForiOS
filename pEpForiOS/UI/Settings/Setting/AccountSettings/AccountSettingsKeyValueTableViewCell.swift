//
//  AccountSettingsKeyValueTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 27/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class AccountSettingsKeyValueTableViewCell: UITableViewCell {

    static let identifier = "KeyValueTableViewCell"
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueTextfield: UITextField!

    @IBOutlet private weak var stackView: UIStackView!

    /// Configure the cell according to the current trait collection
    func configure() {
        let contentSize = traitCollection.preferredContentSizeCategory
        stackView.axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        stackView.spacing = contentSize.isAccessibilityCategory ? 10.0 : 5.0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
}
