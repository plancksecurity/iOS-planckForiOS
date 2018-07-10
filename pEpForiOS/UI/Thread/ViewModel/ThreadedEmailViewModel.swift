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
    weak var delegate: ThreadedEmailViewModelDelegate!
    private let folder: ThreadedFolder
    private var expandedMessages: [Bool]
    private var messageToReply: Message?

    public var currentDisplayedMessage: DisplayedMessage?

    //Needed for segue
    public let displayFolder: Folder

    init(tip: Message, folder: Folder) {
        self.folder = ThreadedFolder(folder: folder)
        messages = tip.messagesInThread()
        self.tip = tip

        //We get the same message reference if we can
        //This is needed so when we update tip it updates the tip in messages array and viceversa
        if let referencedTip = messages.first(where: { message in message == tip }) {
            self.tip = referencedTip
        }

        displayFolder = folder
        expandedMessages = Array(repeating: false, count: messages.count)
        expandedMessages.removeLast()
        expandedMessages.append(true)
    }

    func deleteMessage(at index: Int){
        guard index < messages.count && index >= 0 else {
            return
        }
        deleteInternal(at: index)
    }

    internal func deleteInternal(at index:Int) {
        guard index < messages.count && index >= 0 else {
            return
        }
        folder.deleteSingle(message: messages[index])
        messages.remove(at: index)
        expandedMessages.remove(at: index)
        delegate.emailViewModel(viewModel: self, didRemoveDataAt: index)
        emailDisplayDelegate.emailDisplayDidDelete(message: messages[index])

    }

    internal func deleteInternal(message: Message) {
        guard let index = indexOfMessage(message: message) else {
            return
        }
        deleteMessage(at: index)
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

    internal func indexOfMessage(message: Message)-> Int? {
        for  i in 0...messages.count {
            if messages[i] == message{
                return i
            }
        }
        return nil
    }

    internal func notifyFlag(_ status: Bool, message: Message) {
        if status {
            emailDisplayDelegate.emailDisplayDidFlag(message: message)
        } else {
            emailDisplayDelegate.emailDisplayDidUnflag(message: message)
        }
    }

    func switchFlag(forMessageAt index:Int) {
        guard index < messages.count && index >= 0 else {
            return
        }

        let flagStatus = (messages[index].imapFlags?.flagged ?? false)
        setFlag(to: !flagStatus, for: messages[index])

    }

    func setFlag(to status: Bool){
        for message in messages {
            setFlag(to: status, for: message)
        }
    }

    func setFlag(to status: Bool, for message: Message){
        message.imapFlags?.flagged = status
        message.save()
        notifyFlag(status, message: message)
        delegate.emailViewModeldidChangeFlag(viewModel: self)
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
