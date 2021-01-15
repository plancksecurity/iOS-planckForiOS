//
//  RelationshipKeyPath.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 29/03/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

struct RelationshipKeyPath {

    /// CdFolders
    static let cdFolder_parent_account = CdFolder.RelationshipName.parent + "." +
        CdFolder.RelationshipName.account

    /// CdMessage
    static let cdMessage_parent_account = CdMessage.RelationshipName.parent + "." +
        CdFolder.RelationshipName.account
    static let cdMessage_parent_name = CdMessage.RelationshipName.parent + "." +
        CdFolder.AttributeName.name
    static let cdMessage_parent_typeRawValue = CdMessage.RelationshipName.parent + "." +
        CdFolder.AttributeName.folderTypeRawValue
    static let cdMessage_imap_localFlags = CdMessage.RelationshipName.imap + "." +
        CdImapFields.RelationshipName.localFlags
    static let cdMessage_imap_localFlags_flagDeleted = cdMessage_imap_localFlags + "." +
        CdImapFlags.AttributeName.flagDeleted
    static let cdMessage_imap_serverFlags = CdMessage.RelationshipName.imap + "." +
        CdImapFields.RelationshipName.serverFlags
    static let cdMessage_imap_serverFlags_flagDeleted = cdMessage_imap_serverFlags + "." +
        CdImapFlags.AttributeName.flagDeleted
    static let cdMessage_imap_messageNum = CdMessage.RelationshipName.imap + "." +
        CdImapFields.AttributeName.messageNumber
    static let cdMessage_from_address = CdMessage.RelationshipName.from + "." +
        CdIdentity.AttributeName.address
    static let cdMessage_from_userName = CdMessage.RelationshipName.from + "." +
        CdIdentity.AttributeName.userName

    /// CdAccount
    static let cdAccount_identity_address = CdAccount.RelationshipName.identity + "." +
        CdIdentity.AttributeName.address

}
