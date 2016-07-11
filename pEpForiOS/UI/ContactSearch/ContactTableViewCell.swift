//
//  ContactTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class ContactTableViewCell: UITableViewCell {
    @IBOutlet weak var labelContactDisplayName: UILabel!

    var contact: IContact? = nil {
        didSet {
            if let c = contact {
                labelContactDisplayName.text = c.displayString()
            } else {
                labelContactDisplayName.text = ""
            }
        }
    }
}
