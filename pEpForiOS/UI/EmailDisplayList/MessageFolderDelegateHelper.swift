//
//  MessageFolderDelegateHelper.swift
//  pEp
//
//  Created by Dirk Zimmermann on 21.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageFolderDelegateHelper {
    func newMessage(model: EmailListViewModel,
                    previewMessage: PreviewMessage,
                    referencedMessages: [Message],
                    messages: inout SortedSet<PreviewMessage>) {
        if referencedMessages.isEmpty {
            let index = messages.insert(object: previewMessage)
            let indexPath = IndexPath(row: index, section: 0)
            model.emailListViewModelDelegatedelegate?.emailListViewModel(
                viewModel: model, didInsertDataAt: indexPath)
        } else {
            // (1) Find out which top message this child message belongs to.
            // (2) Update the top message in this list.
            // (3) Find out if that message's thread is displayed.
            // (4) Notify that thread display (if any) that a new message has entered.
            var lowestIndex: Int?
            for msg in referencedMessages {
                let preview = PreviewMessage(withMessage: msg)
                if let index = messages.index(of: preview) {
                    if let currentLow = lowestIndex {
                        if index < currentLow {
                            lowestIndex = index
                        }
                    } else {
                        lowestIndex = index
                    }
                }
            }

            if let _ = lowestIndex {

            }
        }
    }
}
