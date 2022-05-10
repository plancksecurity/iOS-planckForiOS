//
//  ErrorMenuViewCell.swift
//  pEp
//
//  Created by Martín Brude on 10/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

class ErrorMenuViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    func configure(row: ErrorMenuRowProtocol) {
        titleLabel.text = row.title
        switch row.identifier {
        case .copyMessage:
            iconImageView.image = UIImage(named: "")
        case .seeMessage:
            iconImageView.image = UIImage(named: "")
        case .closeNotification:
            iconImageView.image = UIImage(named: "")
        }
    }
}
