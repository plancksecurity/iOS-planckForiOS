//
//  QueryResults.swift
//  MessageModel
//
//  Created by Martin Brude on 27/08/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//
import Foundation
import CoreData
import pEpIOSToolbox

public class QueryResults {

    /// Current search inside monitored folder. If no search is apply, search will be nil.
    public weak var rowDelegate: QueryResultsIndexPathRowDelegate?

    private func get(indexPath: IndexPath?, forType type: NSFetchedResultsChangeType) -> IndexPath? {
        guard let indexPath = indexPath else {
            let error = "QuerryResultController indexPath for NSFetchedResultsChangeType: \(type.rawValue), should never be nil"
            Log.shared.errorAndCrash(message: error)
            return nil
        }
        return indexPath
    }
    
}

// MARK: - QueryResultsControllerDelegate

extension QueryResults: QueryResultsControllerDelegate {

    public func queryResultsControllerWillChangeResults() {
        rowDelegate?.willChangeResults()
    }

    public func queryResultsControllerDidChangeObjectAt(indexPath: IndexPath?,
                                                        forChangeType changeType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch changeType {
        case .delete:
            guard let indexPath = get(indexPath: indexPath, forType: .delete) else { return }
            rowDelegate?.didDeleteRow(indexPath: indexPath)
        case .insert:
            guard let newIndexPath = get(indexPath: newIndexPath, forType: .insert) else { return }
            rowDelegate?.didInsertRow(indexPath: newIndexPath)
        case .move:
            guard let indexPath = get(indexPath: indexPath, forType: .move) else { return }
            guard let newIndexPath = get(indexPath: newIndexPath, forType: .move) else { return }
            rowDelegate?.didMoveRow(from: indexPath, to: newIndexPath)
        case .update:
            guard let indexPath = get(indexPath: indexPath, forType: .update) else { return }
            rowDelegate?.didUpdateRow(indexPath: indexPath)
        @unknown default:
            Log.shared.errorAndCrash("New case is not handled")
        }
    }

    public func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo,
                                                       atSectionIndex sectionIndex: Int,
                                                       for type: NSFetchedResultsChangeType) {
        // Intentionally ignored. query does not need to handle sections
    }

    public func queryResultsControllerDidChangeResults() {
        rowDelegate?.didChangeResults()
    }
}
