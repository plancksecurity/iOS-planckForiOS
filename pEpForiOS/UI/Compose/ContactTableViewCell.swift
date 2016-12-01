//
//  ContactTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class ContactTableViewCell: UITableViewCell {
    @IBOutlet weak var labelContactDisplayName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none
        labelContactDisplayName.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
    }

    var contact: Identity? {
        didSet {
            labelContactDisplayName.text = contact?.displayString ?? ""
        }
    }
}
