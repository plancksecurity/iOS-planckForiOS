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

/// Provides accounts and informs it's delegate about
/// changes (insert, update, delete) in the query's results.
public class AccountQueryResults: QueryResults, QueryResultsProtocol {
    typealias CDO = CdAccount
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T
    private lazy var queryResultController: QueryResultControllerType<QueryResultsController<CDO>> = {
        return QueryResultsController(context: Stack.shared.mainContext,
                                      sortDescriptors: getSortDescriptors(),
                                      delegate: self)
    }()
    
    public var all: [MMO] {
        var results = [Account]()
        do {
            results = try queryResultController.getResults().map { MessageModelObjectUtils.getAccount(fromCdAccount: $0) }
        } catch {
            Log.shared.errorAndCrash("Failed getting results")
        }
        return results
    }
    
    /// Return an Account by index
    ///
    /// - Parameter index: index of desire account
    public subscript(index: Int) -> MMO {
        get {
            do {
                return try getAccount(at: index)
            } catch{
                Log.shared.errorAndCrash("Fail to get account for subscript")
            }
            fatalError("Fail to get account for subscript")
        }
    }
    
    /// - Returns: the number of accounts
    public var count: Int {
        return queryResultController.count
    }
    
    /// Start monitoring the accounts
    public func startMonitoring() throws {
        try queryResultController.startMonitoring()
    }
}

// MARK: - Private

extension AccountQueryResults {
    
    private func getSortDescriptors() -> [NSSortDescriptor] {
        return [NSSortDescriptor(key: CdIdentity.AttributeName.address, ascending: false)]
    }
    
    private func getAccount(at index: Int) throws -> Account {
        let results = try queryResultController.getResults()
        return MessageModelObjectUtils.getAccount(fromCdAccount: results[index])
    }
}
