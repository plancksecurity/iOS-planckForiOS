//
//  UITableView+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

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
}

// MARK: - Insert/Delete Rows

extension UITableView {

    /// Delete the rows passed by parameter
    /// - Parameter indexPaths: The indexPaths of the rows to delete.
    public func deleteRows(at indexPaths: [IndexPath]) {
        beginUpdates()
        deleteRows(at: indexPaths, with: .top)
        endUpdates()
    }

    /// Insert the rows passed by parameter
    /// - Parameter indexPaths: The indexPaths to insert.
    public func insertRows(at indexPaths: [IndexPath]) {
        beginUpdates()
        insertRows(at: indexPaths, with: .fade)
        endUpdates()
    }

    public func insertRows(at indexPathsToInsert: [IndexPath], andDeleteRowsAt indexPathsToDelete: [IndexPath]) {
        beginUpdates()
        insertRows(at: indexPathsToInsert, with: .fade)
        deleteRows(at: indexPathsToDelete, with: .top)
        endUpdates()
    }
}
