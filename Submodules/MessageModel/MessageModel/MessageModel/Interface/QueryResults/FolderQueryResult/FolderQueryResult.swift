//
//  FolderQueryResult.swift
//  MessageModel
//
//  Created by Martin Brude on 31/08/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import Foundation
import CoreData

public protocol FolderQueryResultsProtocol {
    var all: [Folder] { get }
    var count: Int { get }
    subscript(index: Int) -> Folder { get }
    func startMonitoring() throws
    var rowDelegate: QueryResultsIndexPathRowDelegate? { set get }
}

/// Provides folders and informs it's delegate about
/// changes (insert, update, delete) in the query's results.
public class FolderQueryResults: FolderQueryResultsProtocol {
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T
    private lazy var queryResultController: QueryResultControllerType<QueryResultsController<CdFolder>> = {
        return QueryResultsController(context: Stack.shared.mainContext,
                                      delegate: self)
    }()

    /// - Returns: the number of folders
    public var count: Int {
        let results = try? queryResultController.getResults()
        return results?.count ?? 0
    }

    /// All folders
    public var all: [Folder] {
        var results = [Folder]()
        do {
            results = try queryResultController.getResults().map { MessageModelObjectUtils.getFolder(fromCdObject: $0) }
        } catch {
            Log.shared.errorAndCrash("Failed getting results")
        }
        return results
    }

    /// Returns an Folder by index
    ///
    /// - Parameter index: index of desire Folder
    public subscript(index: Int) -> Folder {
        get {
            do {
                return try getFolder(at: index)
            } catch {
                Log.shared.errorAndCrash("Fail to get folder for subscript")
            }
            fatalError("Fail to get folder for subscript")
        }
    }

    /// Where the row updates will be delivered
    public weak var rowDelegate: QueryResultsIndexPathRowDelegate?

    /// Constructor
    public init(rowDelegate: QueryResultsIndexPathRowDelegate?) {
        self.rowDelegate = rowDelegate
    }
    /// Start monitoring the folders
    public func startMonitoring() throws {
        try queryResultController.startMonitoring()
    }
}
// MARK: - Private

extension FolderQueryResults {

    private func getFolder(at index: Int) throws -> Folder {
        let results = try queryResultController.getResults()
        return MessageModelObjectUtils.getFolder(fromCdObject: results[index])
    }
}

///!!! MARTIN This extension is candidate to be in a generic class, QueryResults.
extension FolderQueryResults : QueryResultsControllerDelegate {
    public func queryResultsControllerWillChangeResults() {
        rowDelegate?.willChangeResults()
    }

    /// Notify the delegate there will be changes in the results
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
    /// Notify the delegate something happened in the results sections.
    public func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo,
                                                       atSectionIndex sectionIndex: Int,
                                                       for type: NSFetchedResultsChangeType) {
        // Intentionally ignored. query does not need to handle sections. Override if needed.
    }

    /// Notify the delegate something changed in the results.
    public func queryResultsControllerDidChangeResults() {
        rowDelegate?.didChangeResults()
    }

    private func get(indexPath: IndexPath?, forType type: NSFetchedResultsChangeType) -> IndexPath? {
        guard let indexPath = indexPath else {
            let error = "QuerryResultController indexPath for NSFetchedResultsChangeType: \(type.rawValue), should never be nil"
            Log.shared.errorAndCrash(message: error)
            return nil
        }
        return indexPath
    }
}
