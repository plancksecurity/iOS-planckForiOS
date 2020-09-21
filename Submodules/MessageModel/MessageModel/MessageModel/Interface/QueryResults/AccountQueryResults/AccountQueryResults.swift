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
    /// All accounts
    var all: [Account] { get }
    /// Count all accounts
    var count: Int { get }
    /// Returns an Account according to its index
    subscript(index: Int) -> Account? { get }
    /// Start monitoring Accounts
    func startMonitoring() throws
    /// Where the row updates will be delivered
    var rowDelegate: QueryResultsIndexPathRowDelegate? { set get }
}

/// Provides accounts and informs it's delegate about
/// changes (insert, update, delete) in the query's results.
public class AccountQueryResults: AccountQueryResultsProtocol {
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T
    private lazy var queryResultController:  QueryResultControllerType<QueryResultsController<CdAccount>> = {
        /// cacheName MUST be explicitly nil to disable persistent caching. Otherwise it crashes in random places.
        return QueryResultsController(context: Stack.shared.mainContext,
                                      cacheName: nil,
                                      delegate: self)
    }()

    public var count: Int {
        return all.count
    }

    public var all: [Account] {
        var results = [Account]()
        do {
            results = try queryResultController.getResults().map { MessageModelObjectUtils.getAccount(fromCdAccount: $0) }
        } catch {
            Log.shared.errorAndCrash("Failed getting results")
        }
        return results
    }

    public subscript(index: Int) -> Account? {
        get {
            do {
                return try getAccount(at: index)
            } catch {
                Log.shared.errorAndCrash("Fail to get account for subscript")
            }
            return nil
        }
    }

    public weak var rowDelegate: QueryResultsIndexPathRowDelegate?

    public init(rowDelegate: QueryResultsIndexPathRowDelegate? = nil) {
        self.rowDelegate = rowDelegate
    }

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
}

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

    func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        // Intentionally ignored. Query does not need to handle section.
    }
}

protocol AccountsQueryResultsDelegate: QueryResultsIndexPathRowDelegate {
    //TODO:
}
