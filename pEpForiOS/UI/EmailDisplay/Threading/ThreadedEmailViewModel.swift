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
    var delegate: EmailViewModelDelegate? = nil
    private let folder: ThreadedFolderStub
    private var expandedMessages: [Bool]

    //Needed for segue
    public let displayFolder: Folder

    init(tip: Message, folder: Folder) {
      //  messages = tip.messagesInThread()
        messages = folder.allMessages()
        self.folder = ThreadedFolderStub(folder: folder)
        displayFolder = folder
        expandedMessages = Array(repeating: false, count: messages.count)
        expandedMessages.removeLast()
        expandedMessages.append(true)
    }

    func deleteMessage(at index: Int){
        guard index < messages.count && index >= 0 else {
            return
        }
        folder.deleteSingle(message: messages[index])
        messages.remove(at: index)
    }

    func changeFlagStatus(at index: Int){
        guard index < messages.count && index >= 0,
            let flagged = messages[index].imapFlags?.flagged else {
            return
        }
        messages[index].imapFlags?.flagged = !flagged
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
