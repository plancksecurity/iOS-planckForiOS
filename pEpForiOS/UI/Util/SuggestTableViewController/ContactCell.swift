//
//  ContactCell.swift
//  pEpForiOS
//

//  Created by Yves Landert on 24.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

final class ContactCell: UITableViewCell {
    static let reuseId = "ContactCell"

    @IBOutlet weak var pEpStatusImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!

    var contact: Identity? {
        didSet {
            nameLabel.text = contact?.displayString ?? String()
        }
    }
}
