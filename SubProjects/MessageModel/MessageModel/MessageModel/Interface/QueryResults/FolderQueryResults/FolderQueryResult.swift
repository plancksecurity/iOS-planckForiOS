//
//  FolderQueryResult.swift
//  MessageModel
//
//  Created by Martin Brude on 28/08/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import Foundation
import CoreData
import pEpIOSToolbox

public class FolderQueryResults: QueryResults, QueryResultsProtocol {

    typealias CDO = CdFolder
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T
    private lazy var queryResultController: QueryResultControllerType<QueryResultsController<CDO>> = {
        return QueryResultsController(context: Stack.shared.mainContext,
                                      sortDescriptors: getSortDescriptors(),
                                      delegate: self)
    }()

    public var all: [MMO] {
        var results = [Folder]()
        do {
            results = try queryResultController.getResults().map { MessageModelObjectUtils.getFolder(fromCdObject: $0)  }
        } catch {
            Log.shared.errorAndCrash("Failed getting results")
        }
        return results
    }

    /// Return an Folder by index
    ///
    /// - Parameter index: index of desire Folder
    public subscript(index: Int) -> MMO {
        get {
            do {
                return try getFolder(at: index)
            } catch{
                Log.shared.errorAndCrash("Fail to get account for subscript")
            }
            fatalError("Fail to get account for subscript")
        }
    }

    /// - Returns: the number of folders
    public var count: Int {
        return queryResultController.count
    }

    /// Start monitoring the folders
    public func startMonitoring() throws {
        try queryResultController.startMonitoring()
    }
}

// MARK: - Private

extension FolderQueryResults {

    private func getSortDescriptors() -> [NSSortDescriptor] {
        return [NSSortDescriptor(key: CdFolder.AttributeName.name, ascending: false)]
    }

    private func getFolder(at index: Int) throws -> Folder {
        let results = try queryResultController.getResults()
        return MessageModelObjectUtils.getFolder(fromCdObject: results[index])
    }
}
