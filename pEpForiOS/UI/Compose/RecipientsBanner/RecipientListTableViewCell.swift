//
//  RecipientListTableViewCell.swift
//  pEpForiOS
//
//  Created by Martín Brude on 28/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientListTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    static let cellIdentifier = "RecipientListTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryType = .checkmark
    }
}
