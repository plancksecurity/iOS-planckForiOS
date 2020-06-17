//
//  ContactCell.swift
//  pEpForiOS
//

//  Created by Yves Landert on 24.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

final class ContactCell: UITableViewCell {
    static let reuseId = "ContactCell"

    @IBOutlet private weak var pEpStatusImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!

    private let colon = ":"
    
    var contact: Identity? {
        didSet {
            nameLabel.text = contact?.displayString ?? String()
        }
    }

    func updateCell(name: String = "",
                    email: String = "",
                    pEpStatusIcon: UIImage?) {
        nameLabel.text = name.isEmpty
            ? name
            : name + colon
        emailLabel.text = email
        pEpStatusImageView.image = pEpStatusIcon
    }
}
