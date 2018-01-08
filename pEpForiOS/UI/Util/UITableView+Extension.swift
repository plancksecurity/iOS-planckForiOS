//
//  UITableView+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UITableView {
    /**
     This magic code should trigger a height refresh for table cells.
     */
    public final func updateSize() {
        UIView.performWithoutAnimation {
            beginUpdates()
            endUpdates()
        }
    }

    public final func scrollToTopOf(_ cell: UITableViewCell) {
        var center = contentOffset
        center.y = cell.frame.origin.y - defaultCellHeight
        contentOffset = center
    }
}

protocol TableViewUpdate {
    func updateView()
}
