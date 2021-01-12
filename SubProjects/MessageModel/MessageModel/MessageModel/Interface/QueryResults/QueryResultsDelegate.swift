//
//  QueryResultsDelegate.swift
//  MessageModel
//
//  Created by Xavier Algarra on 08/10/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Subscribers must conform to this to get notified for result changes.
public protocol QueryResultsIndexPathRowDelegate: class {
    /// Call when an insert have been done in the results
    /// - Parameter indexPath: indexPath of the new element inserted
    func didInsertRow(indexPath: IndexPath)

    /// Call when an element have been modify in the results
    /// - Parameter indexPath: indexPath of the modified element
    func didUpdateRow(indexPath: IndexPath)

    /// Call when an element have been deleted from the results
    /// - Parameter indexPath: indexPath of the deleted element
    func didDeleteRow(indexPath: IndexPath)

    /// Call when an element have change position (moved) inside of the results
    /// - Parameter from: original indexPath of the moved element
    /// - Parameter to: destination indexPath of the moved element
    func didMoveRow(from: IndexPath, to: IndexPath)

    /// Notifies the receiver that there will be one or more updates due to an insert, remove,
    /// move, or update.
    func willChangeResults()

    /// Notifies the receiver that all updates have been completed. Results is updated
    func didChangeResults()
}

public protocol QueryResultsIndexPathSectionDelegate: class {
    /// call when a section has to be deleted from the table
    /// - Parameter position: position of the section.
    func didDeleteSection(position: Int)

    /// Call when a new section has to be inserted in the table
    /// - Parameter position: position of the section
    func didInsertSection(position: Int)
}
