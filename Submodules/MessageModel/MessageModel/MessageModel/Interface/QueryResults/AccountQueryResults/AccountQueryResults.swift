//
//  AccountQueryResults.swift
//  MessageModel
//
//  Created by Martin Brude on 31/08/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

public protocol AccountQueryResultsProtocol {
    var all: [Account] { get }
    var count: Int { get }
    subscript(index: Int) -> Account { get }
    func startMonitoring() throws
    var rowDelegate: QueryResultsIndexPathRowDelegate? { set get }
    var filter: AccountQueryResultsFilter? { get }
}

/// Provides accounts and informs it's delegate about
/// changes (insert, update, delete) in the query's results.
public class AccountQueryResults: AccountQueryResultsProtocol {

    private typealias CDO = CdAccount
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T
    private lazy var queryResultController: QueryResultControllerType<QueryResultsController<CDO>> = {
        return QueryResultsController(predicate: getPredicates(),
                                      context: Stack.shared.mainContext,
                                      delegate: self)
    }()
    public var filter: AccountQueryResultsFilter?

    /// - Returns: the number of accounts
    public var count: Int {
        return queryResultController.count
    }

    /// All accounts
    public var all: [Account] {
        var results = [Account]()
        do {
            results = try queryResultController.getResults().map { MessageModelObjectUtils.getAccount(fromCdAccount: $0) }
        } catch {
            Log.shared.errorAndCrash("Failed getting results")
        }
        return results
    }

    /// Returns an Account by index
    ///
    /// - Parameter index: index of desire account
    public subscript(index: Int) -> Account {
        get {
            do {
                return try getAccount(at: index)
            } catch {
                Log.shared.errorAndCrash("Fail to get account for subscript")
            }
            fatalError("Fail to get account for subscript")
        }
    }

    /// Where the row updates will be delivered
    public weak var rowDelegate: QueryResultsIndexPathRowDelegate?

    /// Constructor
    public init(rowDelegate: QueryResultsIndexPathRowDelegate?, filter: AccountQueryResultsFilter? = nil) {
        self.rowDelegate = rowDelegate
        self.filter = filter
    }
    /// Start monitoring the accounts
    public func startMonitoring() throws {
        try queryResultController.startMonitoring()
    }
}
// MARK: - Private

extension AccountQueryResults {

    private func getAccount(at index: Int) throws -> Account {
        let results = try queryResultController.getResults()
        return MessageModelObjectUtils.getAccount(fromCdAccount: results[index])
    }

    private func getPredicates() -> NSPredicate {
        var predicates = [NSPredicate]()
        if let filterPredicate = filter?.predicate {
            predicates.append(filterPredicate)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

///!!! MARTIN This extension is candidate to be in a generic class, QueryResults.
extension AccountQueryResults : QueryResultsControllerDelegate {
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
            let error = "QueryResultController indexPath for NSFetchedResultsChangeType: \(type.rawValue), should never be nil"
            Log.shared.errorAndCrash(message: error)
            return nil
        }
        return indexPath
    }
}
