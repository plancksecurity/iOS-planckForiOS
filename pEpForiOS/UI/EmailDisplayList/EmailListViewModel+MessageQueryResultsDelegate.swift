//
//  EmailListViewModel+MessageQueryResultsDelegate.swift
//  pEp
//
//  Created by Xavier Algarra on 13/03/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension EmailListViewModel : MessageQueryResultsDelegate {
    
    func didInsert(indexPath: IndexPath) {
        if updatesEnabled {
            emailListViewModelDelegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
        }
    }

    func didUpdate(indexPath: IndexPath) {
        if updatesEnabled {
            emailListViewModelDelegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
        }
        emailListViewModelDelegate?.checkIfSplitNeedsUpdate(indexpath: [indexPath])
    }

    func didDelete(indexPath: IndexPath) {
            emailListViewModelDelegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMove(from: IndexPath, to: IndexPath) {
        if updatesEnabled {
            emailListViewModelDelegate?.emailListViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
        }
    }

    func willChangeResults() {
        if updatesEnabled {
            emailListViewModelDelegate?.willReceiveUpdates(viewModel: self)
        }
    }

    func didChangeResults() {
        if updatesEnabled {
            emailListViewModelDelegate?.allUpdatesReceived(viewModel: self)
        } else {
            updatesEnabled = true
        }
    }



}
