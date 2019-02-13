//
//  EmailListViewModel+EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpUtilities
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
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.didDelete(messageFolder: message)
        }
    }

    func emailDisplayDidChangeMarkSeen(message: Message) {
        updateRow(for: message, isSeenStateChange: true)
    }
    
    func emailDisplayDidChangeRating(message: Message) {
        updateRow(for: message)
    }

    private func deleteRow(for message: Message) {
        stopListeningToChanges()
        defer {
            startListeningToChanges()
        }
        DispatchQueue.main.async { [weak self] in
            guard let index = self?.index(of: message) else {
                return
            }
            self?.messages.removeObject(at: index)
            self?.informDeleteRow(at: index)
        }

    }

    private func updateRow(for message: Message, isSeenStateChange: Bool = false) {
        stopListeningToChanges()
        defer {
            startListeningToChanges()
        }
        DispatchQueue.main.async { [weak self] in
            guard let index = self?.index(of: message) else {
                return
            }

            let previewMessage = MessageViewModel(with: message)
            self?.messages.removeObject(at: index)
            self?.messages.insert(object: previewMessage)
            if isSeenStateChange {
                self?.informSeenStateChangeForRow(at: index)
            } else {
                self?.informUpdateRow(at: index)
            }
        }
    }

    private func informUpdateRow(at index: Int) {
        let indexPath = self.indexPath(for: index)
        emailListViewModelDelegate?.emailListViewModel(viewModel: self,
                                                       didUpdateDataAt: [indexPath])
    }

    private func informSeenStateChangeForRow(at index: Int) {
        let indexPath = self.indexPath(for: index)
        emailListViewModelDelegate?.emailListViewModel(viewModel: self,
                                                       didChangeSeenStateForDataAt: [indexPath])
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
