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
    var all: [MMO] { get }
    var count: Int { get }

    init(rowDelegate: QueryResultsIndexPathRowDelegate?)
    subscript(index: Int) -> MMO { get }
    func startMonitoring() throws
}

/// Provides accounts and informs it's delegate about
/// changes (insert, update, delete) in the query's results.
public class AccountQueryResults: QueryResults, AccountQueryResultsProtocol {
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T
    private lazy var queryResultController = getNewQueryResultController()

    public var all: [MMO] {
        var results = [MMO]()
        do {
           results = try queryResultController.getResults().map { MessageModelObjectUtils.getAccount(fromCdAccount: $0) }
        } catch {
            Log.shared.errorAndCrash("Failed getting results")
        }
        return results
    }

    public required init(rowDelegate: QueryResultsIndexPathRowDelegate? = nil) {
        super.init()
        self.rowDelegate = rowDelegate
    }

    /// Return an Account by index
    ///
    /// - Parameter index: index of desire account
    public subscript(index: Int) -> MMO {
        get {
            do {
                return try getAccount(forIndex: index)
            } catch{
                Log.shared.error("Fail to get account for subscript")
                fatalError("Fail to get account for subscript")
            }
        }
    }

    /// - Returns: the number of Accounts
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
        return QueryResultsController(predicate: nil,
                                      context: Stack.shared.mainContext,
                                      cacheName: nil,
                                      sortDescriptors: getSortDescriptors(),
                                      delegate: self)
    }

    private func getSortDescriptors() -> [NSSortDescriptor] {
        return [NSSortDescriptor(key: CdIdentity.AttributeName.address, ascending: false),
                NSSortDescriptor(key: CdAccount.AttributeName.includeFoldersInUnifiedFolders, ascending: true)]
    }

    private func getAccount(forIndex index: Int) throws -> MMO {
        let results = try queryResultController.getResults()
        return MessageModelObjectUtils.getAccount(fromCdAccount: results[index])
    }
}
