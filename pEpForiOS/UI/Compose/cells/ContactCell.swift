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
    static let reuseId = String(describing: self)
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    var contact: Identity? {
        didSet {
            nameLabel.text = contact?.displayString ?? String()
        }
    }

    func updateCell(_ identity: Identity) {
        nameLabel.text = identity.userName
        emailLabel.text = identity.address
    }
}
