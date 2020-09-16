//
//  AccountSettingsOAuthTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 04/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class AccountSettingsOAuthTableViewCell: UITableViewCell {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var oauthLabel: UILabel!

    public func configure(with row : AccountSettingsViewModel.DisplayRow? = nil) {
        guard let row = row else {
            return
        }
        oauthLabel.text = row.title
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        oauthLabel.text = NSLocalizedString("OAuth2 Reauthorization", comment: "OAuth2 Reauthorization label")
        oauthLabel.font = UIFont.pepFont(style: .body, weight: .regular)
    }
}
