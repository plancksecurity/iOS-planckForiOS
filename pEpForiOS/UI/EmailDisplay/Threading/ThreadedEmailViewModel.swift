//
//  ThreadedEmailViewModel.swift
//  pEp
//
//  Created by Borja González de Pablo on 08/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


class ThreadedEmailViewModel {


    internal var messages: [Message]
    internal var tip: Message
    weak var emailDisplayDelegate: EmailDisplayDelegate!
    weak var delegate: EmailViewModelDelegate!
    private let folder: ThreadedFolderWithTop
    private var expandedMessages: [Bool]
    private var messageToReply: Message?

    //Needed for segue
    public let displayFolder: Folder

    init(tip: Message, folder: Folder) {
        self.folder = ThreadedFolderWithTop(folder: folder)
        messages = tip.messagesInThread()
        self.tip = tip
        displayFolder = folder
        expandedMessages = Array(repeating: false, count: messages.count)
        expandedMessages.removeLast()
        expandedMessages.append(true)
    }

    func deleteMessage(at index: Int){
        guard index < messages.count && index >= 0 else {
            return
        }
        emailDisplayDelegate.emailDisplayDidDelete(message: messages[index])
        folder.deleteSingle(message: messages[index])
        messages.remove(at: index)
        expandedMessages.remove(at: index)
        delegate.emailViewModel(viewModel: self, didRemoveDataAt: index)

    }

    func deleteAllMessages(){
        folder.deleteThread(message: tip)
        emailDisplayDelegate.emailDisplayDidDelete(message: tip)
    }

    func addMessage(message: Message) -> Int{
        messages.append(message)
        expandedMessages.append(true)
        return messages.count - 1
    }

    func updateInternal(message: Message) {
        guard let index = indexOfMessage(message: message) else {
            return
        }
        messages[index] = message
        delegate?.emailViewModel(viewModel: self, didUpdateDataAt: index)
    }

    fileprivate func notifyFlag(_ status: Bool) {
        if status {
            emailDisplayDelegate.emailDisplayDidFlag(message: tip)
        } else {
            emailDisplayDelegate.emailDisplayDidUnflag(message: tip)
        }
    }

    //Should only be called from view as it will handle its own update
    func switchFlag(forMessageAt index:Int) {
        guard index < messages.count && index >= 0 else {
            return
        }

        let flagStatus = (messages[index].imapFlags?.flagged ?? false)

        messages[index].imapFlags?.flagged = !flagStatus
        if messages[index] == tip {
            notifyFlag(!flagStatus)
        }
    }

    func setFlag(forMessageAt index: Int, to status: Bool){
        guard index < messages.count && index >= 0 else {
                return
        }
        messages[index].imapFlags?.flagged = status
        messages[index].save()
        updated(message: messages[index])
        if messages[index] == tip {
            notifyFlag(status)
        }
    }

    func setFlag(to status: Bool){
        for message in messages {
            message.imapFlags?.flagged = status
            message.save()
        }
        notifyFlag(status)
    }

    func allMessagesFlagged() -> Bool {
        for message in messages {
            if message.imapFlags?.flagged == false {
                return false
            }
        }
        return true
    }

    func viewModel(for index: Int) -> MessageViewModel? {
        guard index < messages.count && index >= 0 else {
            return nil
        }
        return  MessageViewModel(with: messages[index])
    }

    func rowCount() -> Int {
        return messages.count
    }

    internal func message(at index: Int) -> Message? {
        guard index < messages.count && index >= 0 else {
            return nil
        }
        return messages[index]
    }

    func messageDidExpand(at index: Int){
        expandedMessages[index] = true
    }

    func messageisExpanded(at index: Int) -> Bool{
        return expandedMessages[index]
    }

    func replyToMessage(at index: Int){
        guard index < messages.count && index >= 0 else {
            return
        }
        self.messageToReply = messages[index]
    }

    func getMessageToReply() -> Message? {
        guard let message = messageToReply else {
            return messages.last
        }
        return message
    }
}
