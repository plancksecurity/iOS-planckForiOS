//
//  QueryResultsControllerProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 20.02.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

/// Service that monitors a Core Data fetch request and informs its subscriber whenever
/// the results changes.
protocol QueryResultsControllerProtocol {
    associatedtype T: NSManagedObject

    /// The object that is notified about state and result changes.
    var delegate: QueryResultsControllerDelegate? { get set }

    /// Returns the fetched results of the query. You must call `performFetch()` to populate this
    /// list.
    func getResults() throws -> [T]

    /// - seeAlso: NSFetchedResultsController Section part
    var sections: [NSFetchedResultsSectionInfo]? { get }

    /// - seeAlso: NSFetchedResultsController sectionIndextitles part
    var sectionIndexTitles: [String] { get }

    /// Creates an QueryResultsController for the given request.
    ///
    /// A fetch request on an Core Data Entity (of given type T) is internally crafted, fetched
    /// results are offered and the delegate is informed whenever the results change.
    ///
    /// - note: Important
    /// You must not reuse the same query results controller for multiple queries unless you set
    /// the cacheName to nil.
    ///
    /// Cache
    /// ================================
    /// The controller caches the results unless `cacheName` is explicitly set to nil. If you do
    /// not provide a `cacheName`, a name is generated according to the name of the caller of init.
    /// If the same client code initializes the QueryResultsController multiple times the
    /// generated cache name will stay the same and thus the cache will be maintained across
    /// launches of your application.
    ///
    /// For details see the [Apple docs for NSFetchedResultsController Cache]: https://developer.apple.com/documentation/coredata/nsfetchedresultscontroller#1661453
    ///
    /// - Parameters:
    ///   - predicate:  predicate of fetch request to monitor changes for.
    ///                 If nil, all objects are fetched.
    ///   - context: context to fetch on
    ///   - cacheName: Name of cache.
    ///                Set to nil to deactivate caching.
    ///                If not set, a cache name is generated internally generated that stays
    ///                the same across launches of your application.
    ///   - sectionNameKeyPath: Used to define which will be the field used to calculate the
    ///                         sections division in the data
    ///   - sortDescriptors:    Used to sort the results.
    ///   - delegate: The object that is notified about state and result changes.
    init(predicate: NSPredicate?,
         context: NSManagedObjectContext,
         cacheName: String?,
         sectionNameKeyPath: String?,
         sortDescriptors: [NSSortDescriptor]?,
         delegate: QueryResultsControllerDelegate?)

    /// Fetches query results and starts monitoring changes.
    ///
    /// - Throws:   If the fetch is not successful, upon return contains an error object that
    ///             describes the problem.
    func startMonitoring() throws
}
