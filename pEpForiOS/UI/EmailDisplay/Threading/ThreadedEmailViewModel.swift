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
        if messages[index] == tip {
            emailDisplayDelegate.emailDisplayDidDelete(message: tip)
        }
        folder.deleteSingle(message: messages[index])
        messages.remove(at: index)
        expandedMessages.remove(at: index)
        delegate.emailViewModel(viewModel: self, didRemoveDataAt: index)

    }

    func deleteAllMessages(){
        folder.deleteThread(message: tip)
        emailDisplayDelegate.emailDisplayDidDelete(message: tip)
    }

    fileprivate func notifyFlag(_ status: Bool) {
        if status {
            emailDisplayDelegate.emailDisplayDidFlag(message: tip)
        } else {
            emailDisplayDelegate.emailDisplayDidUnflag(message: tip)
        }
    }

    func setFlag(forMessageAt index: Int, to status: Bool){
        guard index < messages.count && index >= 0 else {
                return
        }
        messages[index].imapFlags?.flagged = status
        messages[index].save()
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

    func message(at index: Int) -> Message? {
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
}
