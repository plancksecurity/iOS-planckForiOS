//
//  EmailListViewModel+MessageFolderDelegate.swift
//  pEp
//
//  Created by Dirk Zimmermann on 21.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension EmailListViewModel: MessageFolderDelegate {
    // MARK: - MessageFolderDelegate (public)

    func didCreate(messageFolder: MessageFolder) {
        messageFolderDelegateHandlingQueue.async {
            self.didCreateInternal(messageFolder: messageFolder)
        }
    }

    func didUpdate(messageFolder: MessageFolder) {
        messageFolderDelegateHandlingQueue.async {
            self.didUpdateInternal(messageFolder: messageFolder)
        }
    }

    func didDelete(messageFolder: MessageFolder) {
        messageFolderDelegateHandlingQueue.async {
            self.didDeleteInternal(messageFolder: messageFolder)
        }
    }

    // MARK: - MessageFolderDelegate (internal)

    private func didCreateInternal(messageFolder: MessageFolder) {
        guard let message = messageFolder as? Message else {
            // The createe is no message. Ignore.
            return
        }
        if !shouldBeDisplayed(message: message){
            return
        }
        // Is a Message (not a Folder)
        if let filter = folderToShow.filter,
            !filter.fulfillsFilter(message: message) {
            // The message does not fit in current filter criteria. Ignore- and do not show it.
            return
        }

        let previewMessage = PreviewMessage(withMessage: message)
        let referencedMessages = threadedMessageFolder.referencedTopMessages(message: message)

        DispatchQueue.main.async { [weak self] in
            if let theSelf = self {
                func insertAsTopMessage() {
                    let index = theSelf.messages.insert(object: previewMessage)
                    let indexPath = IndexPath(row: index, section: 0)
                    theSelf.emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theSelf, didInsertDataAt: indexPath)
                }

                if referencedMessages.isEmpty {
                    insertAsTopMessage()
                } else {
                    if theSelf.currentlyDisplaying(oneOf: referencedMessages) {
                        theSelf.updateThreadListDelegate?.added(message: message)
                    } else {
                        // Incoming message references other messages,
                        // but none of them are displayed right now in this model.
                        // So treat it as a top message.
                        insertAsTopMessage()
                    }
                }
            }
        }
    }

    private func didDeleteInternal(messageFolder: MessageFolder) {
        // Make sure it is a Message (not a Folder). Flag must have changed
        guard let message = messageFolder as? Message else {
            // It is not a Message (probably it is a Folder).
            return
        }
        if !shouldBeDisplayed(message: message) {
            return
        }
        guard let indexExisting = index(of: message) else {
            // We do not have this message in our model, so we do not have to remove it,
            // but it might belong to a thread.
            let referencedMessages = threadedMessageFolder.referencedTopMessages(message: message)
            if !referencedMessages.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    if let theSelf = self {
                        if theSelf.currentlyDisplaying(oneOf: referencedMessages) {
                            theSelf.updateThreadListDelegate?.deleted(message: message)
                        }
                    }
                }
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            if let theSelf = self {
                theSelf.messages.removeObject(at: indexExisting)
                let indexPath = IndexPath(row: indexExisting, section: 0)
                theSelf.emailListViewModelDelegate?.emailListViewModel(
                    viewModel: theSelf,
                    didRemoveDataAt: indexPath)
            }
        }
    }

    private func didUpdateInternal(messageFolder: MessageFolder) {
        // Make sure it is a Message (not a Folder). Flag must have changed
        guard let message = messageFolder as? Message else {
            // It is not a Message (probably it is a Folder).
            return
        }
        if !shouldBeDisplayed(message: message) {
            return
        }

        guard let indexExisting = index(of: message) else {
            // We do not have this updated message in our model yet. It might have been updated in
            // a way, that fulfills the current filters now but did not before the update.
            // Or it has just been decrypted.
            // Forward to didCreateInternal to figure out if we want to display it.
            self.didCreateInternal(messageFolder: messageFolder)
            return
        }

        // We do have this message in our model, so we do have to update it
        guard let existingMessage = messages.object(at: indexExisting) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should have the message at this point")
            return
        }

        let previewMessage = PreviewMessage(withMessage: message)
        if !previewMessage.flagsDiffer(previewMessage: existingMessage) {
            // The only message properties displayed in this view that might be updated
            // are flagged and seen.
            // We got called even the flaggs did not change. Ignore.
            return
        }

        DispatchQueue.main.async { [weak self] in
            if let theSelf = self {
                theSelf.messages.removeObject(at: indexExisting)

                if let filter = theSelf.folderToShow.filter,
                    !filter.fulfillsFilter(message: message) {
                    // The message was included in the model,
                    // but does not fulfil the filter criteria
                    // anymore after it has been updated.
                    // Remove it.
                    let indexPath = IndexPath(row: indexExisting, section: 0)
                    theSelf.emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theSelf, didRemoveDataAt: indexPath)
                    return
                }
                // The updated message has to be shown. Add it to the model ...
                let indexInserted = theSelf.messages.insert(object: previewMessage)
                if indexExisting != indexInserted {
                    Log.shared.warn(
                        component: #function,
                        content:
                        """
When updating a message, the the new index of the message must be the same as the old index.
Something is fishy here.
"""
                    )
                }
                // ...  and inform the delegate.
                let indexPath = IndexPath(row: indexInserted, section: 0)
                theSelf.emailListViewModelDelegate?.emailListViewModel(
                    viewModel: theSelf, didUpdateDataAt: indexPath)

                if theSelf.currentDisplayedMessage?.messageModel == message {
                    theSelf.currentDisplayedMessage?.update(forMessage: message)
                }
            }
        }
    }

    private func shouldBeDisplayed(message: Message) -> Bool {
        if !isInFolderToShow(message: message) {
            return false
        }
        if message.isEncrypted {
            return false
        }
        return true
    }

    private func isInFolderToShow(message: Message) -> Bool {
        if folderToShow is UnifiedInbox {
            if message.parent.folderType == .inbox {
                return true
            }
        } else {
            return message.parent == folderToShow
        }
        return false
    }
}
