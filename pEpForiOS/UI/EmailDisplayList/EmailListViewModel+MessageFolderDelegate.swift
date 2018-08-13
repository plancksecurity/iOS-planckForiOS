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

    func didDelete(messageFolder: MessageFolder, belongingToThread: Set<MessageID>) {
        messageFolderDelegateHandlingQueue.async {
            self.didDeleteInternal(
                messageFolder: messageFolder,
                belongingToThread: belongingToThread)
        }
    }

    // MARK: - MessageFolderDelegate (internal)

    private func didCreateInternal(messageFolder: MessageFolder) {
        guard let message = messageFolder as? Message else {
            // The createe is no message. Ignore.
            return
        }
        if !shouldBeDisplayed(message: message) {
            return
        }

        // With threading, incoming messages might miss the filter
        // but still be considered as a child message.
        var messagePassedFilter = true

        if let filter = folderToShow.filter,
            !filter.fulfillsFilter(message: message) {
            // The message does not fit in current filter criteria.
            if AppSettings.threadedViewEnabled {
                // In case of threading, it could be a child message
                messagePassedFilter = false
            } else {
                // No threading -> this message can be ignored
                return
            }
        }

        let previewMessage = MessageViewModel(with: message)
        let referencedTopMessages = threadedMessageFolder.referencedTopMessages(message: message)

        DispatchQueue.main.async { [weak self] in
            if let theSelf = self {
                func insertAsTopMessage() {
                    if !theSelf.isInFolderToShow(message: message){
                        return
                    }
                    let index = theSelf.messages.insert(object: previewMessage)
                    let indexPath = IndexPath(row: index, section: 0)
                    theSelf.emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theSelf, didInsertDataAt: [indexPath])
                }

                if referencedTopMessages.isEmpty && messagePassedFilter {
                    insertAsTopMessage()
                } else {
                    if let (index, _) = theSelf.referencedTopMessageIndex(
                        messages: referencedTopMessages) {
                        // The thread count might need to be updated
                        theSelf.emailListViewModelDelegate?.emailListViewModel(
                            viewModel: theSelf,
                            didUpdateDataAt: [IndexPath(row: index, section: 0)])
                        if let topMessage = theSelf.currentlyDisplayedMessage(
                            of: referencedTopMessages) {
                            if theSelf.isShowingSingleMessage() {
                                // switch from single to thread
                                theSelf.screenComposer?.emailListViewModel(
                                    theSelf,
                                    requestsShowThreadViewFor: topMessage)
                            } else {
                                // add the new message to the existing thread view
                                theSelf.updateThreadListDelegate?.added(message: message)
                            }
                        }
                    } else {
                        // Incoming message references other messages,
                        // but none of them are displayed right now in this model.
                        // Not in the master view, not in the detail view.
                        // So treat it as a top message even though strictly speaking it's not.
                        insertAsTopMessage()
                    }
                }
            }
        }
    }

    private func didDeleteInternal(messageFolder: MessageFolder,
                                   belongingToThread: Set<MessageID>) {
        // Make sure it is a Message (not a Folder). Flag must have changed
        guard let message = messageFolder as? Message else {
            // It is not a Message (probably it is a Folder).
            return
        }
        if !shouldBeDisplayed(message: message) {
            return
        }
        if let indexExisting = index(of: message) {
            // This concerns a top message

            let isDisplayingThread = AppSettings.threadedViewEnabled &&
                !belongingToThread.isEmpty &&
                isCurrentlyDisplayingDetailsOf(message: message)

            DispatchQueue.main.async { [weak self] in
                guard let theSelf = self else {
                    return
                }
                if isDisplayingThread {
                    // deleting a top message that spans the thread that is currently displayed
                    theSelf.updateThreadListDelegate?.deleted(message: message)

                    if let replacementMessage = CdMessage.latestMessage(
                        fromMessageIdSet: belongingToThread,
                        fulfillingFilter: theSelf.folderToShow.filter)?.message() {
                        // we have the next message in the thread that we can substitute with
                        theSelf.messages.replaceObject(
                            at: indexExisting,
                            with: MessageViewModel(with: replacementMessage))
                        let indexPath = IndexPath(row: indexExisting, section: 0)
                        theSelf.emailListViewModelDelegate?.emailListViewModel(
                            viewModel: theSelf, didUpdateDataAt: [indexPath])
                    }
                } else {
                    // unthreaded top message (or currently not displayed)
                    theSelf.messages.removeObject(at: indexExisting)
                    let indexPath = IndexPath(row: indexExisting, section: 0)
                    theSelf.emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theSelf,
                        didRemoveDataAt: [indexPath])
                }
            }
        } else {
            // We do not have this top message in our model, so we do not have to remove it,
            // but it might belong to a thread.
            let referencedTopMessages = threadedMessageFolder.referencedTopMessages(
                message: message)
            if !referencedTopMessages.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let theSelf = self else {
                        Log.shared.errorAndCrash(component: #function,
                                                 errorString: "Self reference is nil!")
                        return
                    }
                    if theSelf.isCurrentlyDisplayingDetailsOf(oneOf: referencedTopMessages) {
                        theSelf.updateThreadListDelegate?.deleted(message: message)
                    } else {
                        if let (index, _) = theSelf.referencedTopMessageIndex(
                            messages: referencedTopMessages) {
                            // The thread count might need to be updated
                            theSelf.emailListViewModelDelegate?.emailListViewModel(
                                viewModel: theSelf,
                                didUpdateDataAt: [IndexPath(row: index, section: 0)])
                        }
                    }
                }
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

        let referencedMessages = threadedMessageFolder.referencedTopMessages(message: message)

        guard let indexExisting = index(of: message) else {
            // We do not have this updated message in our model yet. It might have been updated in
            // a way, that fulfills the current filters now but did not before the update.
            // Or it has just been decrypted.
            if isCurrentlyDisplayingDetailsOf(oneOf: referencedMessages) {
                updateThreadListDelegate?.updated(message: message)
                return
            } else {
                if referencedMessages.isEmpty {
                    // Forward to didCreateInternal to figure out if we want to display it,
                    // in case it's a top message that now fulfills some filters
                    // it did not before.
                    self.didCreateInternal(messageFolder: messageFolder)
                } else {
                    emailListViewModelDelegate?.emailListViewModel(
                        viewModel: self,
                        didUpdateUndisplayedMessage: message)
                }
                return
            }
        }

        // We do have this message in our model, so we do have to update it
        guard let existingMessage = messages.object(at: indexExisting) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We should have the message at this point")
            return
        }

        let previewMessage = MessageViewModel(with: message)
        if !previewMessage.flagsDiffer(from: existingMessage) {
            // The only message properties displayed in this view that might be updated
            // are flagged and seen.
            // We got called even the flaggs did not change. Ignore.
            return
        }
        update(message: message, previewMessage: previewMessage, atIndex: indexExisting)
    }

    /**
     Updates the given `message` at the given `atIndex`.
     - Note:
       * The message might get deleted if it doesn't fit the filter anymore.
       * The `previewMessage` might seem redundant, but it has already been computed.
     */
    func update(message: Message, previewMessage: MessageViewModel, atIndex indexExisting: Int) {
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
                        viewModel: theSelf, didRemoveDataAt: [indexPath])
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
                    viewModel: theSelf, didUpdateDataAt: [indexPath])

                if theSelf.currentDisplayedMessage?.messageModel == message {
                    theSelf.currentDisplayedMessage?.update(forMessage: message)
                }
            }
        }
    }

    private func shouldBeDisplayed(message: Message) -> Bool {
        if message.isEncrypted ||
            (!AppSettings.threadedViewEnabled && !isInFolderToShow(message: message)) {
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

    /**
     Is the detail view currently displaying messages derived from `Message`?
     I.e., is the given message currently selected in the master view?
     */
    func isCurrentlyDisplayingDetailsOf(message: Message) -> Bool {
        return currentDisplayedMessage?.messageModel == message
    }

    /**
     Like `currentlyDisplaying(message: Message)`, but checks a list of messages.
     */
    func isCurrentlyDisplayingDetailsOf(oneOf messages: [Message]) -> Bool {
        for msg in messages {
            if isCurrentlyDisplayingDetailsOf(message: msg) {
                return true
            }
        }
        return false
    }

    /**
     - Returns: The first currently displayed (top) message out of a given sequence or nil.
     */
    func currentlyDisplayedMessage(of messages: [Message]) -> Message? {
        for msg in messages {
            if isCurrentlyDisplayingDetailsOf(message: msg) {
                return msg
            }
        }
        return nil
    }

    /*
     - Returns: The index (or nil) of the first message from `messages`
     that is currently displayed as a top message.
     */
    private func referencedTopMessageIndex(messages: [Message]) -> (Int, Message)? {
        for msg in messages {
            let preview = MessageViewModel(with: msg)
            if let index = self.messages.index(of: preview) {
                return (index, msg)
            }
        }
        return nil
    }
    /*
     - Returns: If the detail view should change from a view of a single email to
     a thread view.
     */
    private func isShowingSingleMessage() -> Bool {
       return currentDisplayedMessage?.detailType() == .single
    }
}
