//
//  QueryResultsController.swift
//  MessageModel
//
//  Created by Andreas Buff on 20.02.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

// We must inherit from NSObject to be able to conform to NSFetchedResultsControllerDelegate
class QueryResultsController<T: NSManagedObject>: NSObject, QueryResultsControllerProtocol,
NSFetchedResultsControllerDelegate {

    var state = QueryResultsControllerState.uninitialized

    private var frc: NSFetchedResultsController<T>?
    private func setupFRC(with predicate: NSPredicate?,
                          context: NSManagedObjectContext,
                          cacheName: String?,
                          sectionNameKeyPath: String?,
                          sortDescriptors: [NSSortDescriptor]? = []) {
        let fetchRequest = T.createFetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        let createe = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                 managedObjectContext: context,
                                                 sectionNameKeyPath: sectionNameKeyPath,
                                                 cacheName: cacheName)
            as! NSFetchedResultsController<T>
        createe.delegate = self
        frc = createe
    }

    // MARK: - QueryResultsControllerProtocol

    weak var delegate: QueryResultsControllerDelegate?

    func getResults() throws -> [T] {
        guard let controller = frc else {
            Log.shared.errorAndCrash("no controller")
            throw QueryResultsController.InvalidStateError.notInitialized
        }
        guard let results = controller.fetchedObjects else {
            throw QueryResultsController.InvalidStateError.notMonitoring
        }
        return results
    }

    var sections: [NSFetchedResultsSectionInfo]? {
        return frc?.sections
    }

    var sectionIndexTitles: [String] {
        guard let controller = frc else {
            Log.shared.errorAndCrash(message: "no controller")
            return []
        }
        return controller.sectionIndexTitles
    }

    required init(predicate: NSPredicate? = nil,
                  context: NSManagedObjectContext,
                  cacheName: String? = "\(#file)-\(#function)",
                  sectionNameKeyPath: String? = nil,
                  sortDescriptors: [NSSortDescriptor]? = [],
                  delegate: QueryResultsControllerDelegate? = nil) {
        // Is a NSObject, thus we must call super
        super.init()
        setupFRC(with: predicate,
                 context: context,
                 cacheName: cacheName,
                 sectionNameKeyPath: sectionNameKeyPath,
                 sortDescriptors: sortDescriptors)
        self.delegate = delegate
        state = .initialized
    }

    func startMonitoring() throws {
        switch state {
        case .uninitialized:
            throw QueryResultsController.InvalidStateError.notInitialized
        case .initialized, .monitoringResults:
            guard let frc = frc else {
                throw QueryResultsController.InvalidStateError.unknownInternalInvalidState
            }
            try frc.performFetch()
            state = .monitoringResults
        case .updatingResults:
            throw QueryResultsController.InvalidStateError.isCurrentlyUpdatingModel
        }
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.queryResultsControllerWillChangeResults()
        state = .updatingResults
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        delegate?.queryResultsControllerDidChangeObjectAt(indexPath: indexPath,
                                                          forChangeType: type,
                                                          newIndexPath: newIndexPath)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        delegate?.queryResultsControllerDidChangeSection(Info: sectionInfo, atSectionIndex: sectionIndex, for: type)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        state = .monitoringResults
        delegate?.queryResultsControllerDidChangeResults()
    }
}
