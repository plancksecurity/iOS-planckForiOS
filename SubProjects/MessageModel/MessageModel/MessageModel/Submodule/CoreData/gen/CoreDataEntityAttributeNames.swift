// Generated file. DO NOT ALTER MANUALLY!
//
// CoreDataEntityAttributeNames.swift
//

extension CdAccount {
    /// All attribute names as constant String
    struct AttributeName {
        static let includeFoldersInUnifiedFolders = "includeFoldersInUnifiedFolders"
        static let pEpSyncEnabled = "pEpSyncEnabled"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let folders = "folders"
        static let identity = "identity"
        static let servers = "servers"
    }
}

extension CdAttachment {
    /// All attribute names as constant String
    struct AttributeName {
        static let assetUrl = "assetUrl"
        static let contentDispositionTypeRawValue = "contentDispositionTypeRawValue"
        static let data = "data"
        static let fileName = "fileName"
        static let mimeType = "mimeType"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let message = "message"
    }
}

extension CdClientCertificate {
    /// All attribute names as constant String
    struct AttributeName {
        static let importDate = "importDate"
        static let keychainUuid = "keychainUuid"
        static let label = "label"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let serverCredential = "serverCredential"
    }
}

extension CdExtraKey {
    /// All attribute names as constant String
    struct AttributeName {
    }

    /// All relationship names as constant String
    struct RelationshipName {
    }
}

extension CdFolder {
    /// All attribute names as constant String
    struct AttributeName {
        static let existsCount = "existsCount"
        static let folderSeparator = "folderSeparator"
        static let folderTypeRawValue = "folderTypeRawValue"
        static let lastLookedAt = "lastLookedAt"
        static let name = "name"
        static let selectable = "selectable"
        static let shouldDelete = "shouldDelete"
        static let uidNext = "uidNext"
        static let uidValidity = "uidValidity"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let account = "account"
        static let hasToBeMovedHere = "hasToBeMovedHere"
        static let messages = "messages"
        static let parent = "parent"
        static let subFolders = "subFolders"
    }
}

extension CdHeaderField {
    /// All attribute names as constant String
    struct AttributeName {
        static let name = "name"
        static let value = "value"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let message = "message"
    }
}

extension CdIdentity {
    /// All attribute names as constant String
    struct AttributeName {
        static let address = "address"
        static let addressBookID = "addressBookID"
        static let flags = "flags"
        static let language = "language"
        static let userID = "userID"
        static let userName = "userName"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let accounts = "accounts"
        static let messageFrom = "messageFrom"
        static let messagesBcc = "messagesBcc"
        static let messagesCc = "messagesCc"
        static let messagesReceivedBy = "messagesReceivedBy"
        static let messagesReplyTo = "messagesReplyTo"
        static let messagesTo = "messagesTo"
    }
}

extension CdImapFields {
    /// All attribute names as constant String
    struct AttributeName {
        static let contentType = "contentType"
        static let messageNumber = "messageNumber"
        static let mimeBoundary = "mimeBoundary"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let localFlags = "localFlags"
        static let message = "message"
        static let serverFlags = "serverFlags"
    }
}

extension CdImapFlags {
    /// All attribute names as constant String
    struct AttributeName {
        static let flagAnswered = "flagAnswered"
        static let flagDeleted = "flagDeleted"
        static let flagDraft = "flagDraft"
        static let flagFlagged = "flagFlagged"
        static let flagRecent = "flagRecent"
        static let flagSeen = "flagSeen"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let imapLocalFields = "imapLocalFields"
        static let imapServerFields = "imapServerFields"
    }
}

extension CdKey {
    /// All attribute names as constant String
    struct AttributeName {
        static let fingerprint = "fingerprint"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let message = "message"
    }
}

extension CdMessage {
    /// All attribute names as constant String
    struct AttributeName {
        static let comments = "comments"
        static let flagsFromDecryptionRawValue = "flagsFromDecryptionRawValue"
        static let longMessage = "longMessage"
        static let longMessageFormatted = "longMessageFormatted"
        static let needsDecrypt = "needsDecrypt"
        static let pEpProtected = "pEpProtected"
        static let pEpRating = "pEpRating"
        static let received = "received"
        static let sent = "sent"
        static let shortMessage = "shortMessage"
        static let uid = "uid"
        static let uuid = "uuid"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let attachments = "attachments"
        static let bcc = "bcc"
        static let cc = "cc"
        static let from = "from"
        static let imap = "imap"
        static let inReplyTo = "inReplyTo"
        static let keysFromDecryption = "keysFromDecryption"
        static let keywords = "keywords"
        static let optionalFields = "optionalFields"
        static let parent = "parent"
        static let receivedBy = "receivedBy"
        static let references = "references"
        static let replyTo = "replyTo"
        static let targetFolder = "targetFolder"
        static let to = "to"
    }
}

extension CdMessageKeyword {
    /// All attribute names as constant String
    struct AttributeName {
        static let keyword = "keyword"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let messages = "messages"
    }
}

extension CdMessageReference {
    /// All attribute names as constant String
    struct AttributeName {
        static let reference = "reference"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let messagesInReplyTo = "messagesInReplyTo"
        static let messagesReferencing = "messagesReferencing"
    }
}

extension CdServer {
    /// All attribute names as constant String
    struct AttributeName {
        static let address = "address"
        static let authMethod = "authMethod"
        static let automaticallyTrusted = "automaticallyTrusted"
        static let dateLastAuthenticationErrorShown = "dateLastAuthenticationErrorShown"
        static let imapFolderSeparator = "imapFolderSeparator"
        static let manuallyTrusted = "manuallyTrusted"
        static let port = "port"
        static let serverTypeRawValue = "serverTypeRawValue"
        static let transportRawValue = "transportRawValue"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let account = "account"
        static let credentials = "credentials"
    }
}

extension CdServerCredentials {
    /// All attribute names as constant String
    struct AttributeName {
        static let key = "key"
        static let loginName = "loginName"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static let clientCertificate = "clientCertificate"
        static let servers = "servers"
    }
}


