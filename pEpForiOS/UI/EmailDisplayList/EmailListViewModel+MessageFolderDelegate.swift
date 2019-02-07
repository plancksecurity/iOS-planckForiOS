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
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.didCreateInternal(messageFolder: messageFolder)
        }
    }

    func didUpdate(messageFolder: MessageFolder) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.didUpdateInternal(messageFolder: messageFolder)
        }
    }

    func didDelete(messageFolder: MessageFolder) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.didDeleteInternal(
                messageFolder: messageFolder)
        }
    }

    // MARK: - MessageFolderDelegate (internal)

    /// Figures out if we are currently displaying a fake version of the given message
    ///
    /// - Parameter msg: message to search faked version for
    /// - Returns: true if we are currently displaying the given message (assumingly faked version)
    ///            false otherwize
    private func isFakeVersionCurrentlyShown(of msg: Message) -> Bool {
        let existingIndex = messages.index(of: MessageViewModel(with: msg))
        return existingIndex != nil
    }

    private func didCreateInternal(messageFolder: MessageFolder) {
        guard let message = messageFolder as? Message else {
            // The createe is no message. Ignore.
            return
        }
        if !shouldBeDisplayed(message: message) {
            return
        }

        if isFakeVersionCurrentlyShown(of: message) {
            // We are already showing a fake version of this newly fetched message.
            // Ignore.
            return
        }

        // With threading, incoming messages might miss the filter
        // but still be considered as a child message.
        var messagePassedFilter = true

        if let filter = folderToShow.filter,
            !filter.fulfillsFilter(message: message) {
            // The message does not fit in current filter criteria.
            // No threading -> this message can be ignored
            return
        }

        // Check for messages sent to oneself, that are already shown as
        // an incoming message.
        if !messagePassedFilter && message.parent.folderType == .sent {
            let messageIdSet = Set(messages.map { return $0.messageIdentifier })
            if messageIdSet.contains(message.messageIdentifier) {
                return
            }
        }

        let previewMessage = MessageViewModel(with: message)

        let theSelf = self

        func insertAsTopMessage() {
            if !theSelf.isInFolderToShow(message: message){
                return
            }
            let index = theSelf.messages.insert(object: previewMessage)
            let indexPath = IndexPath(row: index, section: 0)
            theSelf.emailListViewModelDelegate?.emailListViewModel(
                viewModel: theSelf, didInsertDataAt: [indexPath])
        }

        insertAsTopMessage()
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

        if let indexExisting = index(of: message) {
            // This concerns a top message
            didDeleteInternal(topMessage: message,
                              atIndex: indexExisting)
        }
    }

    private func didDeleteInternal(topMessage: Message,
                                   atIndex indexExisting: Int) {
        let theSelf = self
        theSelf.messages.removeObject(at: indexExisting)
        let indexPath = IndexPath(row: indexExisting, section: 0)
        emailListViewModelDelegate?.emailListViewModel(
            viewModel: theSelf,
            didRemoveDataAt: [indexPath])
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
            return
        }

        // We do have this message in our (top message) model, so we do have to update it
        guard let existingMessage = messages.object(at: indexExisting) else {
            Logger.frontendLogger.errorAndCrash(
                "We should have the message at this point")
            return
        }

        let previewMessage = MessageViewModel(with: message)
        if !previewMessage.flagsDiffer(from: existingMessage) {
            // The only message properties displayed in this view that might be updated
            // are flagged and seen.
            // We got called even the flaggs did not change. Ignore.
            return
        }
        update(topMessage: message, previewMessage: previewMessage, atIndex: indexExisting)
    }

    /**
     Updates the given `childMessage` if it's currently displayed.
     - Returns: `true` if the `childMessage` was updated, `false` otherwise.
     */
    private func updateIfDisplayed(childMessage: Message, referencedMessages: [Message]) -> Bool {
        if isCurrentlyDisplayingDetailsOf(oneOf: referencedMessages) {
            updateThreadListDelegate?.updated(message: childMessage)
            return true
        }
        return false
    }

    /**
     Updates the given `topMessage` at the given `atIndex`.
     - Note:
       * The message might get deleted if it doesn't fit the filter anymore.
       * The `previewMessage` might seem redundant, but it has already been computed.
     */
    private func update(topMessage: Message,
                        previewMessage: MessageViewModel,
                        atIndex indexExisting: Int) {
        let me = self
        me.messages.removeObject(at: indexExisting)

        if let filter = me.folderToShow.filter,
            !filter.fulfillsFilter(message: topMessage) {
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
            Logger.frontendLogger.warn(
                "When updating a message, the the new index of the message must be the same as the old index. Something is fishy here."
            )
        }
        // ...  and inform the delegate.
        let indexPath = IndexPath(row: indexInserted, section: 0)
        me.emailListViewModelDelegate?.emailListViewModel(viewModel: me,
                                                          didUpdateDataAt: [indexPath])
        if me.currentDisplayedMessage?.messageModel == topMessage {
            me.currentDisplayedMessage?.update(forMessage: topMessage)
        }
    }

    private func shouldBeDisplayed(message: Message) -> Bool {
        if message.isFakeMessage && isInFolderToShow(message: message) {
            return true
        }
        if (!message.parent.showsMessagesNeverSeenByEngine && message.isEncrypted) ||
            (/*!threadedMessageFolder.isThreaded && /*commented out as possible cause for IOS-1244*/*/!isInFolderToShow(message: message)) {
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

    private func modifyThreadCount(at index: Int, _ modifier: (Int) -> (Int)) {
        if let messageModel = messages.object(at: index),
            let messageCount = messageModel.internalMessageCount  {
            messageModel.internalMessageCount = modifier(messageCount)
        }
    }

    private func incThreadCount(at index: Int) {
        modifyThreadCount(at: index) {
            return $0 + 1
        }
    }

    private func decThreadCount(at index: Int) {
        modifyThreadCount(at: index) {
            return $0 - 1
        }
    }

    private func dumpThreadCount(at index: Int?, message: String) {
        if let theIndex = index,
            let messageModel = messages.object(at: theIndex),
            let messageCount = messageModel.internalMessageCount  {
            print("*** \(message) threadCount \(messageCount)")
        }
    }
}
