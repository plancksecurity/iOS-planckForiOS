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

protocol ResetTrustViewModelDelegate: class, TableViewUpdate {
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didInsertDataAt indexPaths: [IndexPath])
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didUpdateDataAt indexPaths: [IndexPath])
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didRemoveDataAt indexPaths: [IndexPath])
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath)
    func willReceiveUpdates(viewModel: ResetTrustViewModel)
    func allUpdatesReceived(viewModel: ResetTrustViewModel)
    func reloadData(viewModel: ResetTrustViewModel)
}

class ResetTrustViewModel {

    var identityQueryResult: IdentityQueryResults
    var delegate: ResetTrustViewModelDelegate?
    var lastSearchTerm = ""

    init() {
        identityQueryResult = IdentityQueryResults()
        identityQueryResult.delegate = self
        do {
            try identityQueryResult.startMonitoring()
        } catch  {
            Log.shared.errorAndCrash(error: error)
        }
    }

    func nameFor(indexPath: IndexPath) -> String {
        let id = identityQueryResult[indexPath.row]
        return id.userNameOrAddress
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

    func resetTrustFor(indexPath: IndexPath) {
        let identity = identityQueryResult[indexPath.row]
        identity.resetTrust()
    }

    func resetTrustAllFor(indexPath: IndexPath) {
        let identity = identityQueryResult[indexPath.row]
        Identity.resetTrustAllIdentities(for: identity)
    }

    func relatedIdentities(indexPath: IndexPath) -> Bool {
        let identity = identityQueryResult[indexPath.row]
        return identity.userHasMoreThenOneIdentity()
    }

    func numberOfRowsPerSection(section: Int) -> Int {
        do {
            return try identityQueryResult.count()
        } catch {
            return 0
        }
    }
}

extension ResetTrustViewModel: QueryResultsDelegate {
    func didInsert(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didInsertDataAt: [indexPath])
    }

    func didUpdate(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didUpdateDataAt: [indexPath])
    }

    func didDelete(indexPath: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMove(from: IndexPath, to: IndexPath) {
        delegate?.resetTrustViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
    }

    func willChangeResults() {
        delegate?.willReceiveUpdates(viewModel: self)
    }

    func didChangeResults() {
        delegate?.allUpdatesReceived(viewModel: self)
    }
}
