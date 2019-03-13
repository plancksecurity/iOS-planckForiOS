//
//  EmailListViewModel+MessageQueryResultsDelegate.swift
//  pEp
//
//  Created by Xavier Algarra on 13/03/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

extension EmailListViewModel : MessageQueryResultsDelegate {
    
    func didInsert(indexPath: IndexPath) {
        emailListViewModelDelegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
    }

    func didUpdate(indexPath: IndexPath) {
        emailListViewModelDelegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
    }

    func didDelete(indexPath: IndexPath) {
        emailListViewModelDelegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMove(from: IndexPath, to: IndexPath) {
        emailListViewModelDelegate?.emailListViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
    }

    func willChangeResults() {
        emailListViewModelDelegate?.willReceiveUpdates(viewModel: self)
    }

    func didChangeResults() {
        emailListViewModelDelegate?.allUpdatesReceived(viewModel: self)
    }



}
