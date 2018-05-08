//
//  FolderCellViewModel+MoveToFolder.swift
//  pEp
//
//  Created by Andreas Buff on 08.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - MoveToFolder Extentions

extension FolderCellViewModel {

    /// Movesw a given message in the folder represented by this model.
    ///
    /// - marks original message as /deleted
    /// - creates a copy of the original messages in the folder represented by this model
    ///
    /// - Parameter message: message to move here
    func moveIn(message: Message) { //BUFF: HERE: tripple check, then append
        let orig = message
        // Create a new message in this folder
        let copy = Message(message: orig)
        copy.parent = folder
        copy.save() //TODO: assure updateOrCreate doe *update* !
        // Mark original msg /deleted
        orig.imapFlags?.deleted = true
        orig.save()
    }
}
