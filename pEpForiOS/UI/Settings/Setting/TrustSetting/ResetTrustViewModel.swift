//
//  ResetTrustViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PEPObjCAdapterFramework


/// delegate protocol to inform about incoming changes in the tableview
protocol ResetTrustViewModelDelegate: class, TableViewUpdate {

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
        identityQueryResult.delegate = self
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

    // workarround to change the first name index
    // as first section name come from the fetch results with "U"
    // due fetch results returns the first letter as a section index and its name which is "Undefined names"
    // is needed to change it to "#" to make it more understandeble
    func indexTitles() -> [String] {
        guard identityQueryResult.count() > 0 else {
            return []
        }
        var titles = identityQueryResult.indexTitles
        if titleForSections(index: 0) == "Undefined names" {
            titles[0] = "#"
        }
        return titles
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
        identityQueryResult = IdentityQueryResults(search: search, delegate: self)
        do {
            try identityQueryResult.startMonitoring()
        } catch {
            Log.shared.errorAndCrash("Failed to fetch data")
            return
        }
    }

    func resetTrust(foridentityAt indexPath: IndexPath) {
        let identity = identityQueryResult[indexPath.section].objects[indexPath.row]
        identity.resetTrust()
    }

    func resetTrustAll(foridentityAt indexPath: IndexPath) {
        let identity = identityQueryResult[indexPath.section].objects[indexPath.row]
        Identity.resetTrustAllIdentities(for: identity)
    }

    func multipleIdentitiesExist(forIdentityAt indexPath: IndexPath) -> Bool {
        let identity = identityQueryResult[indexPath.section].objects[indexPath.row]
        return identity.userHasMoreThenOneIdentity()
    }
}

extension ResetTrustViewModel: QueryResultsDelegate {
    func didInsert(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didInsertDataAt: [indexPath])
        //delegate?.reloadData(viewModel: self)
    }

    func didUpdate(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didUpdateDataAt: [indexPath])
        //delegate?.reloadData(viewModel: self)
    }

    func didDelete(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didRemoveDataAt: [indexPath])
        //delegate?.reloadData(viewModel: self)
    }

    func didMove(from: IndexPath, to: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
        //delegate?.reloadData(viewModel: self)
    }

    func willChangeResults() {
        delegate?.willReceiveUpdates(viewModel: self)
        //delegate?.reloadData(viewModel: self)
    }

    func didChangeResults() {
        delegate?.allUpdatesReceived(viewModel: self)
        //delegate?.reloadData(viewModel: self)
    }
}
