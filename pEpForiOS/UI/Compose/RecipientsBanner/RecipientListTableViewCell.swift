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

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    static let cellIdentifier = "RecipientListTableViewCell"

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
