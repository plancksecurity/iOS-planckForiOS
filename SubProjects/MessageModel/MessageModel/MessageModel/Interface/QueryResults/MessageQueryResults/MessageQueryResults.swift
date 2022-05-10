//
//  MessageQueryResults.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 22/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData
import pEpIOSToolbox

public protocol MessageQueryResultsProtocol {
    init(withFolder folder: DisplayableFolderProtocol,
         filter: MessageQueryResultsFilter?,
         search: MessageQueryResultsSearch?,
         rowDelegate: QueryResultsIndexPathRowDelegate?,
         sectionDelegate: QueryResultsIndexPathSectionDelegate?)
    
    var rowDelegate: QueryResultsIndexPathRowDelegate? { set get }
    var filter: MessageQueryResultsFilter? { get }
    var search: MessageQueryResultsSearch? { get }

    subscript(index: Int) -> Message { get }

    /// All results
    var all: [Message] { get }

    func startMonitoring() throws
    func count() throws -> Int
}

/// Provides all displayable messages in a given folder and informs it's delegate about
/// changes (insert, update, move, delete) in the query's results.
/// - note: Messages will be ordered by `sent` date.
public class MessageQueryResults: MessageQueryResultsProtocol {
    private typealias QueryResultControllerType<T: QueryResultsControllerProtocol> = T

    private lazy var queryResultController = getNewQueryResultController()

    /// Folder being monitored.
    public let folder: DisplayableFolderProtocol
    /// Current filter inside monitored folder. If no filter is apply, filter will be nil.
    public let filter: MessageQueryResultsFilter?
    /// Current search inside monitored folder. If no search is apply, search will be nil.
    public let search: MessageQueryResultsSearch?
    /// Where the row updates will be delivered
    public weak var rowDelegate: QueryResultsIndexPathRowDelegate?

    public var all: [Message] {
        var results = [Message]()
        do {
           results = try queryResultController.getResults().map { MessageModelObjectUtils.getMessage(fromCdMessage: $0) }
        } catch {
            Log.shared.errorAndCrash("Failed fgetting results")
        }
        return results
    }

    /// Init
    ///
    /// Messages will be ordered by date.
    ///
    /// - Parameters:
    ///   - folder: set a folder to monitor and receive messages updates.
    ///   - filter: set a filter to messages inside the folder. Set nil to disable filter.
    ///   - search: set a search to messages inside the folder. Set nil to disable search.
    public required init(withFolder folder: DisplayableFolderProtocol,
                         filter: MessageQueryResultsFilter? = nil,
                         search: MessageQueryResultsSearch? = nil,
                         rowDelegate: QueryResultsIndexPathRowDelegate? = nil,
                         sectionDelegate: QueryResultsIndexPathSectionDelegate? = nil) {
        self.folder = folder
        self.filter = filter
        self.search = search
        self.rowDelegate = rowDelegate
    }

    /// Return a message by index from displayableFolder, after applying filter and search
    ///
    /// - Parameter index: index of desire message
    public subscript(index: Int) -> Message {
        get {
            do {
                return try getMessage(forIndex: index)
            } catch{
                Log.shared.error("Fail to get message for subscript")
                fatalError("Fail to get message for subscript")
            }
        }
    }

    /// Number of messages, after applying filter and search on that DisplayableFolder
    ///
    /// - Returns: number of messages
    /// - Throws: If getting count is not successful, upon return contains an error object that
    /// describes the problem.
    public func count() throws -> Int {
        let results = try queryResultController.getResults()
        return results.count
    }

    public func startMonitoring() throws{
        try queryResultController.startMonitoring()
    }
}

// MARK: - QueryResultsControllerDelegate

extension MessageQueryResults: QueryResultsControllerDelegate {
    func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo,
                                                atSectionIndex sectionIndex: Int,
                                                for type: NSFetchedResultsChangeType) {
        // Intentionally ignored. message query does not need to handle sections
    }


    func queryResultsControllerWillChangeResults() {
        rowDelegate?.willChangeResults()
    }

    func queryResultsControllerDidChangeObjectAt(indexPath: IndexPath?,
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

    func queryResultsControllerDidChangeResults() {
        rowDelegate?.didChangeResults()
    }
}

// MARK: - Private methods

private extension MessageQueryResults {
    private func get(indexPath: IndexPath?, forType type: NSFetchedResultsChangeType) -> IndexPath? {
        guard let indexPath = indexPath else {
            let error = "QuerryResultController indexPath for NSFetchedResultsChangeType: \(type.rawValue), should never be nil"
            Log.shared.errorAndCrash(message: error)
            return nil
        }
        return indexPath
    }

    private func getMessage(forIndex index: Int) throws -> Message {
        let results = try queryResultController.getResults()
        let message = MessageModelObjectUtils.getMessage(fromCdMessage: results[index])
        return message
    }

    private func getPredicates() -> NSPredicate {
        var predicates = [NSPredicate]()
        if let displayableFolderPredicate = getDisplayableFolderPredicate() {
            predicates.append(displayableFolderPredicate)
        }
        if let search = search {
            predicates.append(search.predicate)
        }
        if let filterPredicate = filter?.predicate {
            predicates.append(filterPredicate)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func getDisplayableFolderPredicate() -> NSPredicate? {
        return folder.messagesPredicate
    }

    private func getSortDescriptors() -> [NSSortDescriptor] {
        // Messages are supposed to be sorted by date sent (newest first).
        // To avoid UI issues with moving messages for messages that have the same date sent,
        // we additionally sort by uuid and uid.
        return [NSSortDescriptor(key: CdMessage.AttributeName.sent, ascending: false),
                NSSortDescriptor(key: CdMessage.AttributeName.uuid, ascending: false),
                NSSortDescriptor(key: CdMessage.AttributeName.uid, ascending: false)]
    }

    private func getNewQueryResultController()
        -> QueryResultControllerType<QueryResultsController<CdMessage>> {
        return QueryResultsController(predicate: getPredicates(),
                                      context: Stack.shared.mainContext,
                                      cacheName: nil,
                                      sortDescriptors: getSortDescriptors(),
                                      delegate: self)
    }
}
