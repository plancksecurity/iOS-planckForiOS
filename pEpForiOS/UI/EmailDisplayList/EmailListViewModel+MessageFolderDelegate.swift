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
        let referencedIndices = threadedMessageFolder.referenced(
            messageIdentifiers: messages.array(), message: message)

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

                if referencedIndices.isEmpty && messagePassedFilter {
                    insertAsTopMessage()
                } else {
                    if let currentlyDisplayedIndex =
                        theSelf.currentlyDisplayedIndex(of: referencedIndices) {
                        if theSelf.isShowingSingleMessage() {
                            // switch from single to thread
                            if let theMessageViewModel =
                                theSelf.messages[safe: currentlyDisplayedIndex],
                                let theMsg = theMessageViewModel.message() {
                                theSelf.screenComposer?.emailListViewModel(
                                    theSelf,
                                    requestsShowThreadViewFor: theMsg)
                            }
                        } else {
                            // add the new message to the existing thread view
                            theSelf.updateThreadListDelegate?.added(message: message)
                        }
                    }

                    if let index = referencedIndices.first {
                        if messagePassedFilter {
                            theSelf.messages.removeObject(at: index)
                            let newIndex = theSelf.messages.insert(object: previewMessage)

                            theSelf.emailListViewModelDelegate?.emailListViewModel(
                                viewModel: theSelf,
                                didUpdateDataAt: [IndexPath(row: newIndex, section: 0)])

                            if newIndex != index {
                                theSelf.emailListViewModelDelegate?.emailListViewModel(
                                    viewModel: theSelf,
                                    didMoveData: IndexPath(row: index, section: 0),
                                    toIndexPath: IndexPath(row: newIndex, section: 0))
                            }
                        } else {
                            theSelf.incThreadCount(at: index)
                            theSelf.emailListViewModelDelegate?.emailListViewModel(
                                viewModel: theSelf,
                                didUpdateDataAt: [IndexPath(row: index, section: 0)])
                        }
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
            didDeleteInternal(topMessage: message,
                              atIndex: indexExisting,
                              belongingToThread: belongingToThread)
        } else {
            // We do not have this top message in our model, so we do not have to remove it there,
            // but it might belong to some top message's thread so we might have to update
            // that top message.
            if AppSettings.threadedViewEnabled {
                didDeleteInternal(notTopMessage: message, belongingToThread: belongingToThread)
            }
        }
    }

    private func didDeleteInternal(topMessage: Message,
                                   atIndex indexExisting: Int,
                                   belongingToThread: Set<MessageID>) {
        if AppSettings.threadedViewEnabled {
            let isDisplayingThread = !belongingToThread.isEmpty &&
                isCurrentlyDisplayingDetailsOf(message: topMessage)

            var aReplacementMessage: Message?
            MessageModel.performAndWait { [weak self] in
                guard let theSelf = self else {
                    return
                }
                aReplacementMessage = Message.latestMessage(
                    fromMessageIdSet: belongingToThread,
                    fulfillingFilter: theSelf.folderToShow.filter)
            }

            if let replacementMessage = aReplacementMessage {
                messages.replaceObject(
                    at: indexExisting,
                    with: MessageViewModel(with: replacementMessage))
            } else {
                messages.removeObject(at: indexExisting)
            }

            func notifyUI(theModel: EmailListViewModel) {
                let indexPath = IndexPath(row: indexExisting, section: 0)

                if isDisplayingThread {
                    // deleting a top message that spans the thread that is currently displayed
                    updateThreadListDelegate?.deleted(message: topMessage)
                }

                if let replacementMessage = aReplacementMessage {
                    // we have the next message in the thread that we can substitute with
                    emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theModel, didUpdateDataAt: [indexPath])
                    updateThreadListDelegate?.tipDidChange(to: replacementMessage)
                } else {
                    emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theModel,
                        didRemoveDataAt: [indexPath])
                }
            }

            DispatchQueue.main.sync { [weak self] in
                if let theSelf = self {
                    notifyUI(theModel: theSelf)
                }
            }
        } else {
            messages.removeObject(at: indexExisting)
            DispatchQueue.main.sync { [weak self] in
                if let theSelf = self {
                    let indexPath = IndexPath(row: indexExisting, section: 0)
                    emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theSelf,
                        didRemoveDataAt: [indexPath])
                }
            }
        }
    }

    private func didDeleteInternal(notTopMessage: Message,
                                   belongingToThread: Set<MessageID>) {
        let referencedIndices = threadedMessageFolder.referenced(
            messageIdentifiers: messages.array(), belongingToThread: belongingToThread)
        if !referencedIndices.isEmpty {
            DispatchQueue.main.sync { [weak self] in
                guard let theSelf = self else {
                    return
                }

                if theSelf.isCurrentlyDisplayingDetailsOf(oneOf: referencedIndices) {
                    theSelf.updateThreadListDelegate?.deleted(message: notTopMessage)
                }

                if let index = referencedIndices.first {
                    // The thread count might need to be updated
                    decThreadCount(at: index)
                    theSelf.emailListViewModelDelegate?.emailListViewModel(
                        viewModel: theSelf,
                        didUpdateDataAt: [IndexPath(row: index, section: 0)])
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

        var referencedMessages = [Message]()
        MessageModel.performAndWait { [weak self] in
            referencedMessages =
                self?.threadedMessageFolder.referencedTopMessages(message: message) ?? []
        }

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
    private func update(message: Message, previewMessage: MessageViewModel, atIndex indexExisting: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Assumtion taken over from original implementaion: It's ok here.
                return
            }
            me.messages.removeObject(at: indexExisting)

            if let filter = me.folderToShow.filter,
                !filter.fulfillsFilter(message: message) {
                // The message was included in the model,
                // but does not fulfil the filter criteria
                // anymore after it has been updated.
                // Remove it.
                let indexPath = IndexPath(row: indexExisting, section: 0)
                me.emailListViewModelDelegate?.emailListViewModel(viewModel: me,
                                                                  didRemoveDataAt: [indexPath])
                return
            }
            // The updated message has to be shown. Add it to the model ...
            let indexInserted = me.messages.insert(object: previewMessage)
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
            me.emailListViewModelDelegate?.emailListViewModel(viewModel: me,
                                                              didUpdateDataAt: [indexPath])
            if me.currentDisplayedMessage?.messageModel == message {
                me.currentDisplayedMessage?.update(forMessage: message)
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
     Is the detail view currently displaying messages derived from the given `message`?
     I.e., is the given `message` currently selected in the master view?
     */
    func isCurrentlyDisplayingDetailsOf(message: Message) -> Bool {
        return currentDisplayedMessage?.messageModel == message
    }

    /**
     Like `isCurrentlyDisplayingDetailsOf(message: Message)`, but checks a list of messages.
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
     Is the detail view currently displaying messages derived from `messageViewModel`?
     I.e., is the given `messageViewModel` currently selected in the master view?
     */
    func isCurrentlyDisplayingDetailsOf(messageViewModel: MessageViewModel) -> Bool {
        if let currentMessageModel = currentDisplayedMessage?.messageModel {
            return
                currentMessageModel.messageIdentifier == messageViewModel.messageIdentifier &&
                    currentMessageModel.uid == messageViewModel.uid
        } else {
            return false
        }
    }

    /**
     Like `isCurrentlyDisplayingDetailsOf(messageViewModel: MessageViewModel)`,
     but checks a list of `MessageViewModel` indices.
     */
    func isCurrentlyDisplayingDetailsOf(oneOf messageViewModelIndices: [Int]) -> Bool {
        if currentlyDisplayedIndex(of: messageViewModelIndices) != nil {
            return true
        } else {
            return false
        }
    }

    /**
     - Returns: The first currently displayed (top) index out of an array of `MessageViewModel`
     indices or nil.
     */
    func currentlyDisplayedIndex(of messageViewModelIndices: [Int]) -> Int? {
        for i in messageViewModelIndices {
            if let messageViewModel = messages[safe: i] {
                if isCurrentlyDisplayingDetailsOf(messageViewModel: messageViewModel) {
                    return i
                }
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

    private func incThreadCount(at index: Int) {
        if let messageModel = messages.object(at: index),
            let messageCount = messageModel.internalMessageCount  {
            messageModel.internalMessageCount = messageCount + 1
        }
    }

    private func decThreadCount(at index: Int) {
        if let messageModel = messages.object(at: index),
            let messageCount = messageModel.internalMessageCount  {
            messageModel.internalMessageCount = messageCount - 1
        }
    }
}
