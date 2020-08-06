//
//  AccountSettingsDangerousTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 28/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class AccountSettingsDangerousTableViewCell: UITableViewCell {
    static let identifier = "DangerousTableViewCell"

    @IBOutlet private weak var titleLabel: UILabel!

    public func configure(with row : AccountSettingsViewModel.ActionRow? = nil) {
        guard let row = row else {
            return
        }
        titleLabel.text = row.title
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.pepFont(style: .body, weight: .regular)
    }
}
