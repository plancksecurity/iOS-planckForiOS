//
//  AccountQueryResults.swift
//  MessageModel
//
//  Created by Martin Brude on 27/08/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData
import pEpIOSToolbox

public protocol AccountQueryResultsProtocol {
    typealias MMO = Account
    typealias CDObject = CdAccount

    var filter: AccountQueryResultsFilter? { get }
    var all: [MMO] { get }
    var count: Int { get }

    init(filter: AccountQueryResultsFilter?, rowDelegate: QueryResultsIndexPathRowDelegate?)

    subscript(index: Int) -> MMO { get }

    func startMonitoring() throws
}

/// Provides all accounts and informs it's delegate about
/// changes (insert, update, delete) in the query's results.
public class AccountQueryResults: QueryResults, AccountQueryResultsProtocol {
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T
    private lazy var queryResultController = getNewQueryResultController()
    public let filter: AccountQueryResultsFilter?

    public var all: [MMO] {
        var results = [MMO]()
        do {
           results = try queryResultController.getResults().map { MessageModelObjectUtils.getAccount(fromCdAccount: $0) }
        } catch {
            Log.shared.errorAndCrash("Failed getting results")
        }
        return results
    }

    /// Init
    ///
    /// - Parameters:
    ///   - filter: set a filter to messages inside the folder. Set nil to disable filter.
    public required init(filter: AccountQueryResultsFilter? = nil,
                         rowDelegate: QueryResultsIndexPathRowDelegate? = nil) {
        self.filter = filter
        super.init()
        self.rowDelegate = rowDelegate
    }

    /// Return a Account by index from displayableFolder, after applying filter
    ///
    /// - Parameter index: index of desire message
    public subscript(index: Int) -> Account {
        get {
            do {
                return try getAccount(forIndex: index)
            } catch{
                Log.shared.error("Fail to get message for subscript")
                fatalError("Fail to get message for subscript")
            }
        }
    }

    /// - Returns: the number of Accounts, after applying filter
    public var count: Int {
        return queryResultController.count
    }

    public func startMonitoring() throws {
        try queryResultController.startMonitoring()
    }
}

// MARK: - Private

extension AccountQueryResults {

    private func getNewQueryResultController() -> QueryResultControllerType<QueryResultsController<CDObject>> {
        return QueryResultsController(predicate: getPredicates(),
                                      context: Stack.shared.mainContext,
                                      cacheName: nil,
                                      sortDescriptors: getSortDescriptors(),
                                      delegate: self)
    }

    private func getPredicates() -> NSPredicate {
        var predicates = [NSPredicate]()
        if let filterPredicate = filter?.predicate {
            predicates.append(filterPredicate)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func getSortDescriptors() -> [NSSortDescriptor] {
        // Accounts are supposed to be sorted by ......... address (?)
        return [NSSortDescriptor(key: CdIdentity.AttributeName.address, ascending: false),
                NSSortDescriptor(key: CdAccount.AttributeName.includeFoldersInUnifiedFolders, ascending: true)]
    }

    private func getAccount(forIndex index: Int) throws -> MMO {
        let results = try queryResultController.getResults()
        return MessageModelObjectUtils.getAccount(fromCdAccount: results[index])
    }
}
