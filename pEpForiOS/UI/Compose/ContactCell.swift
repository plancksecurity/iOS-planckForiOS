//
//  ContactCell.swift
//  pEpForiOS
//

//  Created by Yves Landert on 24.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

class ContactCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    func updateCell(_ recipient: Recipient) {
        nameLabel.text = recipient.name
        emailLabel.text = recipient.email
    }
    
    var contact: Identity? {
        didSet {
            nameLabel.text = contact?.displayString ?? String()
        }
    }
}
