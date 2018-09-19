//
//  PEPSwipeTableViewCell.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

import SwipeCellKit

/**
 Swipe table view cell with the typical pEp selection look.
 */
class PEPSwipeTableViewCell: SwipeTableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        PEPTableViewCell.configureSelectedBackgroundViewForPep(tableViewCell: self)
    }
}
