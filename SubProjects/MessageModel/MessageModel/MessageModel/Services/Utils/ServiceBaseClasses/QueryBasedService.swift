//
//  QueryBasedService.swift
//  MessageModel
//
//  Created by Andreas Buff on 19.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

protocol QueryBasedServiceProtocol: OperationBasedServiceProtocol {
    associatedtype T: NSManagedObject

    /// The fetched results. You MUST use the fetched objects on the provided context only!
    var results: [T] { get }

    /// Forwarded from QueryResultsControllerDelegate. Find docs there.
    /// This default implementation ignores `WillChangeResults` and does nothing.
    ///
    /// - note: I made this private for now. If we need more flexibility, we might want to add it
    ///         to QueryBasedServiceProtocol and make it override-able.
    /// - seeAlso: QueryResultsControllerDelegate docs
    func handleWillChangeResults()

    /// - seeAlso: QueryResultsControllerDelegate docs
    ///
    /// This default implementation ignores `WillChangeResults` and does nothing.
    ///
    /// - Parameter index: index of removed object in `results`.
    func handleDidRemove(objectAt index: Int)

    /// - seeAlso: QueryResultsControllerDelegate docs
    ///
    /// This default implementation ignores `WillChangeResults` and does nothing.
    ///
    /// - Parameter index: index of inserted object in `results`.
    func handleDidInsert(objectAt index: Int)

    /// - seeAlso: QueryResultsControllerDelegate docs
    ///
    /// This default implementation ignores `WillChangeResults` and does nothing.
    ///
    /// - Parameter index: index of updated object in `results`.
    func handleDidUpdate(objectAt index: Int)

    /// Forwarded from QueryResultsControllerDelegate. Find docs there.
    ///
    /// The default implementation calls next.
    ///
    /// - note: I made this private for now. If we need more flexibility, we might want to add it
    ///         to QueryBasedServiceProtocol and make it override-able.
    /// - seeAlso: QueryResultsControllerDelegate docs
    func handleDidChangeResults()
}

/// QueryResultsController based Service.
/// Every Service that depends on CoreData queries MUST inherit form this class.
///
/// Use this as base class if you create a Service that works over results of a Core Data query.
/// It handles the complete start/finish/stop cycle for you and takes care about registering for
/// start/end background tasks. It also takes care to run the service again in case the query
/// results changed.
/// Usage:
/// * init with a NSPredicate of your choice
/// * override `operations()`
///
/// You can get and use the fetched results with `results`.
/// - note: You MUST use the fetched objects on the `privateMoc` only!
///
/// Reminder: You MUST override `operations()`.
class QueryBasedService<T: NSManagedObject>: OperationBasedService, QueryBasedServiceProtocol {

    /// Internal QueryResultsController
    private var qrc: QueryResultsController<T>

    // MARK: - Life Cycle

    /// - Parameters:
    ///   - useSerialQueue: if true, operations are processed with maxConcurrentOperationCount == 1
    ///                     otherwize the OperationQueue's default is kept.
    ///   - backgroundTaskManager: see Service.init for docs
    ///   - predicate: predicate to monitor query for. Pass nil if you want ALL objects of type T.
    ///   - cacheName:  forwarded to QueryResultsController. See docs there.
    ///                 - note: Read the docs well if you are planning to use a cache. It is *very*
    ///                         likly that it acts not the way you might expect it to work.
    ///   - sortDescriptors: used to sort the results.
    ///   - errorPropagator: see Service.init for docs
    init(useSerialQueue: Bool = false,
         backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
         predicate: NSPredicate?,
         cacheName: String? = nil,
         sortDescriptors: [NSSortDescriptor],
         errorPropagator: ErrorContainerProtocol?) {
        let moc: NSManagedObjectContext = Stack.shared.changePropagatorContext
        self.qrc = QueryResultsController<T>(predicate: predicate,
                                             context: moc,
                                             cacheName: cacheName,
                                             sortDescriptors: sortDescriptors,
                                             delegate: nil)
        super.init(useSerialQueue: useSerialQueue,
                   backgroundTaskManager: backgroundTaskManager,
                   context: moc,
                   errorPropagator: errorPropagator)
        // Start monitoring query
        self.qrc.delegate = self
        do {
            try qrc.startMonitoring()
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }

    // MARK: - QueryBasedServiceProtocol

    var results: [T] {
        do {
            return try qrc.getResults()
        } catch {
            Log.shared.errorAndCrash(error: error)
            return []
        }
    }

    func handleWillChangeResults() {
        // Does nothing. Override for your needs.
    }

    func handleDidRemove(objectAt index: Int) {
        // Does nothing. Override for your needs.
    }

    func handleDidInsert(objectAt index: Int) {
        // Does nothing. Override for your needs.
    }

    func handleDidUpdate(objectAt index: Int) {
        // Does nothing. Override for your needs.
    }

    func handleDidChangeResults() {
        next()
    }
}

// MARK: - QueryResultsController

extension QueryBasedService: QueryResultsControllerDelegate {


    func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo,
                                                atSectionIndex sectionIndex: Int,
                                                for type: NSFetchedResultsChangeType) {
        // Intentionally ignored. service query does not need to handle sections
    }

    func queryResultsControllerWillChangeResults() {
        handleWillChangeResults()
    }

    func queryResultsControllerDidChangeObjectAt(indexPath: IndexPath?,
                                                 forChangeType changeType: NSFetchedResultsChangeType,
                                                 newIndexPath: IndexPath?) {
        switch changeType {
        case .delete:
            guard let index = indexPath?.item else {
                Log.shared.errorAndCrash("No indexpath")
                return
            }
            handleDidRemove(objectAt: index)
        case .insert:
            guard let index = newIndexPath?.item else {
                Log.shared.errorAndCrash("No indexpath")
                return
            }
            handleDidInsert(objectAt: index)
        case .move:
            // Intentionally ignored. I do currenly not see a use case for this.
            break
        case .update:
            guard let index = indexPath?.item else {
                Log.shared.errorAndCrash("No indexpath")
                return
            }
            handleDidUpdate(objectAt: index)
        @unknown default:
            Log.shared.errorAndCrash("F....ing unknown case.")
        }

    }

    func queryResultsControllerDidChangeResults() {
        handleDidChangeResults()
    }
}
