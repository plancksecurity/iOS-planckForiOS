//
//  EmailDisplayViewModel+QueryResultsIndexPathRowDelegate.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
// MARK: - QueryResultsIndexPathRowDelegate

extension EmailDisplayViewModel: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
           if updatesEnabled {
               delegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
           }
       }

       func didUpdateRow(indexPath: IndexPath) {
           if updatesEnabled {
               delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
           }
           delegate?.checkIfSplitNeedsUpdate(indexpath: [indexPath]) //BUFF: hirntot? (read as: obsolete?)
       }

       func didDeleteRow(indexPath: IndexPath) {
               delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
       }

       func didMoveRow(from: IndexPath, to: IndexPath) {
           if updatesEnabled {
               delegate?.emailListViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
           }
       }

       func willChangeResults() {
           if updatesEnabled {
               delegate?.willReceiveUpdates(viewModel: self)
           }
       }

       func didChangeResults() {
           if updatesEnabled {
               delegate?.allUpdatesReceived(viewModel: self)
           } else {
               updatesEnabled = true
           }
       }
}
