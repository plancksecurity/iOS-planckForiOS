//
//  RecipientListTableViewCell.swift
//  pEpForiOS
//
//  Created by Martín Brude on 28/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class RecipientListTableViewCell: UITableViewCell {

    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!

    public static let cellIdentifier = "RecipientListTableViewCell"

    func configure(address: String, username: String?) {
        if let username {
            usernameLabel.text = username
            usernameLabel.isHidden = false
        } else {
            usernameLabel.isHidden = true
        }
        addressLabel.text = address
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryType = .none
        selectionStyle = .none
        usernameLabel.textColor = UIColor.pEpSecondaryColor()
        addressLabel.textColor = UIColor.pEpLabelColor()
        usernameLabel.setPEPFont(style: .body, weight: .regular)
        addressLabel.setPEPFont(style: .body, weight: .regular)
    }
}
