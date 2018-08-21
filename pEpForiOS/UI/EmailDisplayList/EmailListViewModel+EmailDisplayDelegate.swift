//
//  EmailListViewModel+EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension EmailListViewModel: EmailDisplayDelegate {
    func emailDisplayDidFlag(message: Message) {
        updateRow(for: message)
    }

    func emailDisplayDidUnflag(message: Message) {
        updateRow(for: message)
    }

    func emailDisplayDidDelete(message: Message) {

        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I am lost")
                return
            }
            me.didDelete(messageFolder: message, belongingToThread: message.threadMessageIdSet())
        }
    }

    private func deleteRow(for message: Message) {
        stopListeningToChanges()
        defer {
            startListeningToChanges()
        }
        guard let index = self.index(of: message) else {
            return
        }
        messages.removeObject(at: index)
        informDeleteRow(at: index)
        startListeningToChanges()
    }

    private func updateRow(for message: Message) {
        stopListeningToChanges()
        defer {
            startListeningToChanges()
        }
        guard let index = self.index(of: message) else {
            return
        }
        
        let previewMessage = MessageViewModel(with: message)
        messages.removeObject(at: index)
        _ = messages.insert(object: previewMessage)
        informUpdateRow(at: index)
    }

    private func informUpdateRow(at index: Int) {
        let indexPath = self.indexPath(for: index)
        emailListViewModelDelegate?.emailListViewModel(viewModel: self,
                                                       didUpdateDataAt: [indexPath])
    }

    private func informDeleteRow(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)

        emailListViewModelDelegate?.emailListViewModel(viewModel: self,
                                                       didRemoveDataAt: [indexPath])
    }

    private func indexPath(for index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
}
