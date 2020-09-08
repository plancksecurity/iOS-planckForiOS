//
//  QueryResultsControllerDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 20.02.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

/// Protocol subscribers must conform to get notified about result changes.
protocol QueryResultsControllerDelegate: class {

    /// Noftifies the receiver that the query results controller is about to start processing of
    /// one or more changes (due to an insert, delete, move or update).
    func queryResultsControllerWillChangeResults()

    /// Notifies the receiver that one object did change (due to an insert, delete, move or update).
    ///
    /// - Parameters:
    ///   - object: modified object
    ///   - changeType: type of the change
    ///   - newIndexPath: index path of the changed object *after* the change happened
    func queryResultsControllerDidChangeObjectAt(indexPath: IndexPath?,
                                                 forChangeType changeType: NSFetchedResultsChangeType,
                                                 newIndexPath: IndexPath?)   

    /// Noftifies the receiver that the query results controller has completed processing of
    /// one or more changes (due to an insert, delete, move or update).
    func queryResultsControllerDidChangeResults()
}
