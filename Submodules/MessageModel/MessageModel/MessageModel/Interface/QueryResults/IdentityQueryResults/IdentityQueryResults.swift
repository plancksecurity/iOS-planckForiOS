//
//  IdentityQueryResults.swift
//  MessageModel
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//
import Foundation
import CoreData
import pEpIOSToolbox

public class IdentityQueryResults: IdentityQueryResultsProtocol {

    private lazy var queryResultController = getNewQueryResultController()

    public let search: IdentityQueryResultsSearch?
    public weak var rowDelegate: QueryResultsIndexPathRowDelegate?
    public weak var sectionDelegate: QueryResultsIndexPathSectionDelegate?

    public required init(search: IdentityQueryResultsSearch? = nil,
                         rowDelegate: QueryResultsIndexPathRowDelegate? = nil,
                         sectionDelegate: QueryResultsIndexPathSectionDelegate? = nil) {
        self.search = search
        self.rowDelegate = rowDelegate
        self.sectionDelegate = sectionDelegate
    }

    public subscript(index: Int) -> IdentityQueryResultsSectionProtocol {
        get {
            return getSection(index: index)
        }
    }

    public func count() -> Int {
        let sections = queryResultController.sections?.count ?? 0
        return sections
    }

    public var indexTitles: [String] {
        return queryResultController.sectionIndexTitles
    }

    public func startMonitoring() throws {
        try queryResultController.startMonitoring()
    }
}

// MARK: - QueryResultsControllerDelegate

extension IdentityQueryResults: QueryResultsControllerDelegate {
    
    func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo,
                                                atSectionIndex sectionIndex: Int,
                                                for type: NSFetchedResultsChangeType) {
        switch type {
        case .delete:
            sectionDelegate?.didDeleteSection(position: sectionIndex)
        case .insert:
            sectionDelegate?.didInsertSection(position: sectionIndex)
        case .move:
            Log.shared.errorAndCrash(message: "not posible case, sections are not moved")
        case .update:
            Log.shared.errorAndCrash(message: "not posible case, sections are not updated")
        @unknown default:
            Log.shared.errorAndCrash("New case is not handled")

        }
    }

    func queryResultsControllerWillChangeResults() {
        rowDelegate?.willChangeResults()
    }

    func queryResultsControllerDidChangeObjectAt(indexPath: IndexPath?,
                                                 forChangeType changeType: NSFetchedResultsChangeType,
                                                 newIndexPath: IndexPath?) {
        switch changeType {
        case .delete:
            guard let indexPath = get(indexPath: indexPath) else { return }
            rowDelegate?.didDeleteRow(indexPath: indexPath)
        case .insert:
            guard let newIndexPath = get(indexPath: newIndexPath) else { return }
            rowDelegate?.didInsertRow(indexPath: newIndexPath)
        case .move:
            guard let indexPath = get(indexPath: indexPath) else { return }
            guard let newIndexPath = get(indexPath: newIndexPath) else { return }
            rowDelegate?.didMoveRow(from: indexPath, to: newIndexPath)
        case .update:
            guard let indexPath = get(indexPath: indexPath) else { return }
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

extension IdentityQueryResults {

    private struct Section: IdentityQueryResultsSectionProtocol {

        subscript(index: Int) -> Identity {
            return objects[index]
        }

        var name: String

        var title: String?

        var count: Int {
            return objects.count
        }

        var objects: [Identity]
    }

    private func getSection(index: Int) -> Section {

        guard
            let NSFetchSection = queryResultController.sections?[index],
            let objects = NSFetchSection.objects as? [CdIdentity] else {
            Log.shared.errorAndCrash(message: "Section not found")
            return Section(name: "", title: nil, objects: [])
        }

        let identities = objects.compactMap({ MessageModelObjectUtils.getIdentity(fromCdIdentity: $0) })

        return Section(name: NSFetchSection.name, title: NSFetchSection.indexTitle, objects: identities)
    }

    private func get(indexPath: IndexPath?) -> IndexPath? {
        guard let indexPath = indexPath else {
            Log.shared.errorAndCrash("No index")
            return nil
        }
        return indexPath
    }

    private func getIdentity(forIndex index: Int) throws -> Identity {
        let results = try queryResultController.getResults()
        let identity = MessageModelObjectUtils.getIdentity(fromCdIdentity: results[index])
        return identity
    }

    private func getPredicates() -> NSPredicate {
        var predicates = [NSPredicate]()
        if let search = search {
            predicates.append(search.predicate)
        }
        predicates.append(CdIdentity.PredicateFactory.isNotMySelf())
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func getSortDescriptor() -> [NSSortDescriptor] {
        var sortDescriptors = [NSSortDescriptor]()
        let sortByUsername = NSSortDescriptor(key: CdIdentity.AttributeName.userName,
                                    ascending: true,
                                    selector: #selector( NSString.localizedCaseInsensitiveCompare))
        let sortByAddress = NSSortDescriptor(key: CdIdentity.AttributeName.address,
                                     ascending: true,
                                     selector: #selector(NSString.localizedCaseInsensitiveCompare))
        sortDescriptors.append(sortByUsername)
        sortDescriptors.append(sortByAddress)
        return sortDescriptors
    }

    private func getSectionNameKeyPath() -> String {
        return "sectionTitle"
    }

    private func getNewQueryResultController()
        -> QueryResultsController<CdIdentity> {
           return QueryResultsController<CdIdentity>(predicate: getPredicates(),
                                         context: Stack.shared.mainContext, cacheName: nil,
                                         sectionNameKeyPath: getSectionNameKeyPath(),
                                         sortDescriptors: getSortDescriptor(),
                                         delegate: self)
    }
}
