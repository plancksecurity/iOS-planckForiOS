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
     This magic code should trigger a height refresh for table cells,
     with an optional block to execute after the size got updated, but outside of
     the no-animation block.
     */
    public final func updateSize(andExecuteBlock: (() -> Void)? = nil) {
        UIView.performWithoutAnimation {
            beginUpdates()
            endUpdates()
            if let theBlock = andExecuteBlock {
                GCD.onMain {
                    theBlock()
                }
            }
        }
    }

    public final func scrollToTopOf(_ cell: UITableViewCell) {
        var center = contentOffset
        center.y = cell.frame.origin.y - ComposeHelpers.defaultCellHeight
        contentOffset = center
    }
}

protocol TableViewUpdate {
    func updateView()
}
