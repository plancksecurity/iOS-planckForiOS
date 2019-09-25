//
//  ResetTrustViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol ResetTrustViewModelDelegate: class, TableViewUpdate {
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didInsertDataAt indexPaths: [IndexPath])
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didUpdateDataAt indexPaths: [IndexPath])
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didRemoveDataAt indexPaths: [IndexPath])
    func resetTrustViewModel(viewModel: ResetTrustViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath)
    func willReceiveUpdates(viewModel: ResetTrustViewModel)
    func allUpdatesReceived(viewModel: ResetTrustViewModel)
}

class ResetTrustViewModel {

    var identityQueryResult: IdentityQueryResults
    var delegate: ResetTrustViewModelDelegate?

    init() {
        identityQueryResult = IdentityQueryResults()
        identityQueryResult.delegate = self
    }

    func startMonitoring() {
        try? identityQueryResult.startMonitoring()
    }

    func nameFor(indexPath: IndexPath) -> String {
        let id = identityQueryResult[indexPath.row]
        return id.userNameOrAddress
    }

    func resetTrustFor(indexPath: IndexPath) {

    }

    func resetTrustAllFor(indexPath: IndexPath) {

    }

    func numberOfSections() -> Int {
        //!!!: To Be Implemented
        return 1
    }

    func titleForSection(section: Int) -> String {
        //!!!: To Be Implemented
        return "test"
    }

    func numberOfRowsPerSection(section: Int) -> Int {
        do {
            return try identityQueryResult.count()
        } catch {
            return 0
        }
    }

    func indexElements() -> [String] {
        //!!!: To Be Implemented
        return ["T"]
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
