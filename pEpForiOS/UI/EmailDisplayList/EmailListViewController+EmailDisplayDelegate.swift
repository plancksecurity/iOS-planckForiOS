//
//  EmailListViewController+EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension EmailListViewModel: EmailDisplayDelegate {


    func emailDisplayDidFlagMessage(message: Message) {
        updateRow(for: message)
    }

    func emailDisplayDidUnflagMessage(message: Message) {
        updateRow(for: message)
    }

    func emailDisplaydidDeleteMessage(message: Message) {
        deleteRow(for: message)
    }

    private func deleteRow(for message: Message) {
        guard let index = self.index(of: message) else {
            return
        }
        messages?.removeObject(at: index)
        informDeleteRow(at: index)
    }

    private func updateRow(for message: Message) {
        guard let index = self.index(of: message) else {
            return
        }
        let previewMessage = PreviewMessage(withMessage: message)
        messages?.removeObject(at: index)
        _ = messages?.insert(object: previewMessage)
        informUpdateRow(at: index)
    }

    private func informUpdateRow(at index: Int) {
        let indexPath = self.indexPath(for: index)
        delegate?.emailListViewModel(viewModel: self, didUpdateDataAt: indexPath)
    }

    private func informDeleteRow(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)

        delegate?.emailListViewModel(viewModel: self, didRemoveDataAt: indexPath)
    }

    private func indexPath(for index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
}

