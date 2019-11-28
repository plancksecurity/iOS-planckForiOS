//
//  EmailListViewModel+QueryResultsDelegate.swift
//  pEp
//
//  Created by Xavier Algarra on 13/03/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension EmailListViewModel : QueryResultsDelegate {

    func didInserSection(position: Int) {
        //there are no sections in the EmailList
    }

    func didDeleteSection(position: Int) {
        //there are no sections in the EmailList
    }
    
    func didInsertCell(indexPath: IndexPath) {
        if updatesEnabled {
            emailListViewModelDelegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
        }
    }

    func didUpdateCell(indexPath: IndexPath) {
        if updatesEnabled {
            emailListViewModelDelegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
        }
        emailListViewModelDelegate?.checkIfSplitNeedsUpdate(indexpath: [indexPath])
    }

    func didDeleteCell(indexPath: IndexPath) {
            emailListViewModelDelegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMoveCell(from: IndexPath, to: IndexPath) {
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
