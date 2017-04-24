//
//  UITableView+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UITableView {
    public final func updateSize() {
        beginUpdates()
        endUpdates()
    }

    public final func scrollToTopOf(_ cell: UITableViewCell) {
        var center = contentOffset
        center.y = cell.frame.origin.y - defaultCellHeight
        contentOffset = center
    }
}
