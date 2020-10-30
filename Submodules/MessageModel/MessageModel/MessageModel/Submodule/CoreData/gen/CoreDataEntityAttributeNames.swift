//// Generated file. DO NOT ALTER MANUALLY!//

extension CdAccount {

    /// All attribute names as constant String
    struct AttributeName {
        static public let includeFoldersInUnifiedFolders = "includeFoldersInUnifiedFolders"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let folders = "folders"
        static public let identity = "identity"
        static public let servers = "servers"
    }
}

extension CdAttachment {

    /// All attribute names as constant String
    struct AttributeName {
        static public let assetUrl = "assetUrl"
        static public let contentDispositionTypeRawValue = "contentDispositionTypeRawValue"
        static public let data = "data"
        static public let fileName = "fileName"
        static public let mimeType = "mimeType"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let message = "message"
    }
}

extension CdClientCertificate {

    /// All attribute names as constant String
    struct AttributeName {
        static public let importDate = "importDate"
        static public let keychainUuid = "keychainUuid"
        static public let label = "label"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let serverCredential = "serverCredential"
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
        static public let existsCount = "existsCount"
        static public let folderSeparator = "folderSeparator"
        static public let folderTypeRawValue = "folderTypeRawValue"
        static public let lastLookedAt = "lastLookedAt"
        static public let name = "name"
        static public let selectable = "selectable"
        static public let shouldDelete = "shouldDelete"
        static public let uidNext = "uidNext"
        static public let uidValidity = "uidValidity"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let account = "account"
        static public let hasToBeMovedHere = "hasToBeMovedHere"
        static public let messages = "messages"
        static public let parent = "parent"
        static public let subFolders = "subFolders"
    }
}

extension CdHeaderField {

    /// All attribute names as constant String
    struct AttributeName {
        static public let name = "name"
        static public let value = "value"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let message = "message"
    }
}

extension CdIdentity {

    /// All attribute names as constant String
    struct AttributeName {
        static public let address = "address"
        static public let addressBookID = "addressBookID"
        static public let flags = "flags"
        static public let language = "language"
        static public let userID = "userID"
        static public let userName = "userName"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let accounts = "accounts"
        static public let messageFrom = "messageFrom"
        static public let messagesBcc = "messagesBcc"
        static public let messagesCc = "messagesCc"
        static public let messagesReceivedBy = "messagesReceivedBy"
        static public let messagesReplyTo = "messagesReplyTo"
        static public let messagesTo = "messagesTo"
    }
}

extension CdImapFields {

    /// All attribute names as constant String
    struct AttributeName {
        static public let contentType = "contentType"
        static public let messageNumber = "messageNumber"
        static public let mimeBoundary = "mimeBoundary"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let localFlags = "localFlags"
        static public let message = "message"
        static public let serverFlags = "serverFlags"
    }
}

extension CdImapFlags {

    /// All attribute names as constant String
    struct AttributeName {
        static public let flagAnswered = "flagAnswered"
        static public let flagDeleted = "flagDeleted"
        static public let flagDraft = "flagDraft"
        static public let flagFlagged = "flagFlagged"
        static public let flagRecent = "flagRecent"
        static public let flagSeen = "flagSeen"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let imapLocalFields = "imapLocalFields"
        static public let imapServerFields = "imapServerFields"
    }
}

extension CdKey {

    /// All attribute names as constant String
    struct AttributeName {
        static public let fingerprint = "fingerprint"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let message = "message"
    }
}

extension CdMessage {

    /// All attribute names as constant String
    struct AttributeName {
        static public let comments = "comments"
        static public let flagsFromDecryptionRawValue = "flagsFromDecryptionRawValue"
        static public let longMessage = "longMessage"
        static public let longMessageFormatted = "longMessageFormatted"
        static public let needsDecrypt = "needsDecrypt"
        static public let pEpProtected = "pEpProtected"
        static public let pEpRating = "pEpRating"
        static public let received = "received"
        static public let sent = "sent"
        static public let shortMessage = "shortMessage"
        static public let uid = "uid"
        static public let uuid = "uuid"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let attachments = "attachments"
        static public let bcc = "bcc"
        static public let cc = "cc"
        static public let from = "from"
        static public let imap = "imap"
        static public let inReplyTo = "inReplyTo"
        static public let keysFromDecryption = "keysFromDecryption"
        static public let keywords = "keywords"
        static public let optionalFields = "optionalFields"
        static public let parent = "parent"
        static public let receivedBy = "receivedBy"
        static public let references = "references"
        static public let replyTo = "replyTo"
        static public let targetFolder = "targetFolder"
        static public let to = "to"
    }
}

extension CdMessageKeyword {

    /// All attribute names as constant String
    struct AttributeName {
        static public let keyword = "keyword"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let messages = "messages"
    }
}

extension CdMessageReference {

    /// All attribute names as constant String
    struct AttributeName {
        static public let reference = "reference"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let messagesInReplyTo = "messagesInReplyTo"
        static public let messagesReferencing = "messagesReferencing"
    }
}

extension CdServer {

    /// All attribute names as constant String
    struct AttributeName {
        static public let address = "address"
        static public let authMethod = "authMethod"
        static public let automaticallyTrusted = "automaticallyTrusted"
        static public let dateLastAuthenticationErrorShown = "dateLastAuthenticationErrorShown"
        static public let imapFolderSeparator = "imapFolderSeparator"
        static public let manuallyTrusted = "manuallyTrusted"
        static public let port = "port"
        static public let serverTypeRawValue = "serverTypeRawValue"
        static public let transportRawValue = "transportRawValue"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let account = "account"
        static public let credentials = "credentials"
    }
}

extension CdServerCredentials {

    /// All attribute names as constant String
    struct AttributeName {
        static public let key = "key"
        static public let loginName = "loginName"
    }

    /// All relationship names as constant String
    struct RelationshipName {
        static public let clientCertificate = "clientCertificate"
        static public let servers = "servers"
    }
}

