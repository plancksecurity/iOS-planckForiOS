//
//  PEPTableViewCell.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Table view cell with the typical pEp selection look.
 */
class PEPTableViewCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        PEPTableViewCell.configureSelectedBackgroundViewForPep(tableViewCell: self)
    }

    public static func configureSelectedBackgroundViewForPep(tableViewCell: UITableViewCell) {
        let tableViewCellSelectedbackgroundView = UIView()
        tableViewCellSelectedbackgroundView.backgroundColor =
            UIColor.pEpGreen.withAlphaComponent(0.2)
        tableViewCell.selectedBackgroundView = tableViewCellSelectedbackgroundView
    }
}
