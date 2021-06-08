//
//  ResetTrustViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

/// delegate protocol to inform about incoming changes in the tableview
protocol ResetTrustViewModelDelegate: class {

    /// called when new data will be introduced
    ///
    /// - Parameters:
    ///   - viewModel: viewModel who performs the call
    ///   - indexPaths: indexPath to be inserted
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didInsertDataAt indexPaths: [IndexPath])

    /// called when existing data needs to be updateds
    ///
    /// - Parameters:
    ///   - viewModel: viewModel who performs the call
    ///   - indexPaths: indexPath to be updated
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didUpdateDataAt indexPaths: [IndexPath])

    /// called when existing data needs to be removed
    ///
    /// - Parameters:
    ///   - viewModel: viewModel who performs the call
    ///   - indexPaths: indexpath to be removed
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didRemoveDataAt indexPaths: [IndexPath])

    /// called when existing data must change its position
    ///
    /// - Parameters:
    ///   - viewModel: viewModel who performs the call
    ///   - atIndexPath: original indexpath of the data
    ///   - toIndexPath: destination indexpath of the data
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath)

    /// called when new section must be displayed in the tableview
    /// - Parameters:
    ///   - viewModel: viewModel who performs the call
    ///   - atPosition: position where the section will be inserted
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didInsertSectionAt position: Int)

    /// called when section must be deleted in the tableview
    /// - Parameters:
    ///   - viewModel: viewModel who performs the call
    ///   - atPosition: position where the section will be deleted
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didDeleteSectionAt position: Int)

    /// called when some new operation will be executed
    /// operation can be: update, delte, move, insert
    /// - Parameter viewModel: viewModel who performs the call
    func willReceiveUpdates(viewModel: ResetTrustViewModel)

    /// called when there is no more operations to be executed
    /// operation can be: update, delte, move, insert
    /// - Parameter viewModel: viewModel who performs the call
    func allUpdatesReceived(viewModel: ResetTrustViewModel)

    /// called when data must be reload
    ///
    /// - Parameter viewModel: viewModel who performs the call
    func reloadData(viewModel: ResetTrustViewModel)
}

class ResetTrustViewModel {

    private var identityQueryResult: IdentityQueryResults
    private var lastSearchTerm = ""
    weak var delegate: ResetTrustViewModelDelegate?

    init() {
        identityQueryResult = IdentityQueryResults()
        identityQueryResult.rowDelegate = self
        identityQueryResult.sectionDelegate = self
        do {
            try identityQueryResult.startMonitoring()
        } catch  {
            Log.shared.errorAndCrash(error: error)
        }
    }

    func numberOfSections() -> Int {
        return identityQueryResult.count()
    }

    func titleForSections(index: Int) -> String? {
        return identityQueryResult[index].name
    }

    func indexTitles() -> [String] {
        guard identityQueryResult.count() > 0 else {
            return []
        }
        return identityQueryResult.indexTitles
    }

    func numberOfRowsIn(section: Int) -> Int {
        return identityQueryResult[section].objects.count
    }

    func nameFor(indexPath: IndexPath) -> String {
        return identityQueryResult[indexPath.section][indexPath.row].userNameOrAddress
    }

    func detailFor(indexPath: IndexPath) -> String {
        return identityQueryResult[indexPath.section][indexPath.row].address
    }

    public func removeSearch() {
        setNewSearchAndReload(search: nil)
    }

    public func setSearch(forSearchText txt: String) {
        if txt == lastSearchTerm {
            // Happens e.g. when initially setting the cursor in search bar.
            return
        }
        lastSearchTerm = txt

        let search = txt == "" ? nil : IdentityQueryResultsSearch(searchTerm: txt)
        setNewSearchAndReload(search: search)
    }

    private func setNewSearchAndReload(search: IdentityQueryResultsSearch?) {
        resetQueryResultsAndReload(search: search)
    }

    // Every time filter or search changes, we have to rest QueryResults
    private func resetQueryResultsAndReload(search: IdentityQueryResultsSearch? = nil) {
        defer { delegate?.reloadData(viewModel: self) }
        identityQueryResult = IdentityQueryResults(search: search,
                                                   rowDelegate: self,
                                                   sectionDelegate: self)
        do {
            try identityQueryResult.startMonitoring()
        } catch {
            Log.shared.errorAndCrash("Failed to fetch data")
            return
        }
    }

    func resetTrust(foridentityAt indexPath: IndexPath, completion: @escaping () -> ()) {
        let identity = identityQueryResult[indexPath.section].objects[indexPath.row]
        identity.resetTrust(completion: completion)
    }

    func resetTrustAll(foridentityAt indexPath: IndexPath, completion: @escaping () -> ()) {
        let identity = identityQueryResult[indexPath.section].objects[indexPath.row]
        Identity.resetTrustAllIdentities(for: identity, completion: completion)
    }

    func multipleIdentitiesExist(forIdentityAt indexPath: IndexPath) -> Bool {
        let identity = identityQueryResult[indexPath.section].objects[indexPath.row]
        return identity.userHasMoreThenOneIdentity()
    }
}

extension ResetTrustViewModel: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didInsertDataAt: [indexPath])
    }

    func didUpdateRow(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didUpdateDataAt: [indexPath])
    }

    func didDeleteRow(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
    }

    func willChangeResults() {
        delegate?.willReceiveUpdates(viewModel: self)
    }

    func didChangeResults() {
        delegate?.allUpdatesReceived(viewModel: self)
    }
}

extension ResetTrustViewModel: QueryResultsIndexPathSectionDelegate {
    func didInsertSection(position: Int) {
        delegate?.resetTrustViewModel(viewModel: self, didInsertSectionAt: position)
    }

    func didDeleteSection(position: Int) {
        delegate?.resetTrustViewModel(viewModel: self, didDeleteSectionAt: position)
    }
}
