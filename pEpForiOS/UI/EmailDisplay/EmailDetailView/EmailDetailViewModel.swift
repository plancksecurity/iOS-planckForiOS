//
//  EmailDetailViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol EmailDetailViewModelDelegate: EmailDisplayViewModelDelegate {
    //BUFF: All moved to EmailDisplayViewModelDelegate. Will be filled with list specific stuff soon. Stay tuned.
}

/// Reports back currently shown email changes
protocol EmailDetailViewModelDisplayMessageDelegate: EmailDisplayViewModelDelegate {
    //BUFF: All moved to EmailDisplayViewModelDelegate. Will be filled with list specific stuff soon. Stay tuned.
}

// 
class EmailDetailViewModel: EmailDisplayViewModel {
    // Property coll delegate
    weak var delegate: EmailDetailViewModelDelegate?

    init(messageQueryResults: MessageQueryResults? = nil,
         delegate: EmailDisplayViewModelDelegate? = nil,
         folderToShow: DisplayableFolderProtocol) {
        super.init(messageQueryResults: messageQueryResults,
                   folderToShow: folderToShow)
        self.messageQueryResults.rowDelegate = self
    }

    public func replaceMessageQueryResults(with qrc: MessageQueryResults) {
        messageQueryResults = qrc
        messageQueryResults.rowDelegate = self
        do {
            try messageQueryResults.startMonitoring()
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }

    override func informDelegateToReloadData() {
           delegate?.reloadData(viewModel: self)
       }
}

// MARK: - QueryResultsIndexPathRowDelegate

extension EmailDetailViewModel: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didInsertDataAt: [indexPath])
    }

    func didUpdateRow(indexPath: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: [indexPath])
    }

    func didDeleteRow(indexPath: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: [indexPath])
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        delegate?.emailListViewModel(viewModel: self, didMoveData: from, toIndexPath: to)
    }

    func willChangeResults() {
        delegate?.willReceiveUpdates(viewModel: self)
    }

    func didChangeResults() {
        delegate?.allUpdatesReceived(viewModel: self)
    }
}
