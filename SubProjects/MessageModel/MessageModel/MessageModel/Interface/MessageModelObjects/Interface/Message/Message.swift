//
//  Message.swift
//  MailModel
//
//  Created by Dirk Zimmermann on 23/09/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

public class Message: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdMessage
    let moc: NSManagedObjectContext
    let cdObject: T

    func cdMessage() -> CdMessage? {
        return cdObject
    }

    // MARK: - Life Cycle

    required init(cdObject: T, context: NSManagedObjectContext) {
        // Done here too to assure propper imap even *before* the cdObject's MOC has been saved.
        cdObject.assureImapAndFlagsNotNil()
        self.cdObject = cdObject
        self.moc = context
    }

    //!!! MUST go away. Mesage + NSManagedObjectContext
    @available(*, deprecated, message: "You must not use this! Mega wrong, causes weird issue like crashing the local test server.")
    public convenience init(uuid: String,
                            uid: Int = 0,
                            parentFolder parent: Folder,
                            session: Session = Session.main) {
        let moc = session.moc
        let createe = CdMessage(context: moc)

        createe.uuid = uuid
        createe.uid = Int32(uid)
        createe.parent = parent.cdFolder()

        self.init(cdObject: createe, context: moc)
    }

    /// Creates a new message taking over all values of the givven message with the exception of
    /// the UID, which defaults to zero if no UID is passed.
    ///
    /// A deep copy of properties is used.
    ///
    /// Note: UID defaults to 0.
    ///
    /// - Parameters:
    ///   - uid: uid to set to the created message. If nil UID will be 0
    ///   - msg: message to take over values from.
    public convenience init(uid: Int = 0, message msg: Message) {
        let moc = msg.moc
        let createe = msg.cdObject.cloneWithZeroUID(context: moc)
        createe.uid = Int32(uid)
        self.init(cdObject: createe, context: moc)
    }

    // MARK: - Forwarded Getter & Setter

    public var uuid: MessageID {
        get {
            guard let safeUuid = cdObject.uuid else {
                Log.shared.errorAndCrash("mandatory field missing")
                return "NONSENSE"
            }
            return safeUuid
        }
        set {
            cdObject.uuid = newValue
        }
    }

    public var imapFlags: ImapFlags {
        get {
            return cdObject.imapFields(context: moc).localFlags!.imapFlags()
        }
        set {
            // Set the property of the cdObject (cdObject.imap instead of cdObject.imap.localFlags)
            // to assure change is triggert in NSFetchedResultsController
            let newImap = cdObject.imapFields(context: moc)
            newImap.localFlags = newValue.cdObject
            cdObject.imap = newImap
        }
    }

    public var parent: Folder {
        get {
            return cdObject.parent!.folder()
        }
        set {
            cdObject.parent = newValue.cdObject
        }
    }

    /// This is set when a message has to be moved to another folder.
    public var targetFolder: Folder? {
        get {
            guard let target = cdObject.targetFolder else {
                return nil
            }
            return Folder(cdObject: target, context: moc)
        }
        set {
            cdObject.targetFolder = newValue?.cdObject
        }
    }

    public var underAttack: Bool {
        get {
            return cdObject.underAttack
        }
    }

    public var shortMessage: String? {
        get {
            return cdObject.shortMessage
        }
        set {
            cdObject.shortMessage = newValue
        }
    }

    public var longMessage: String? {
        get {
            return cdObject.longMessage
        }
        set {
            cdObject.longMessage = newValue
        }
    }

    public var longMessageFormatted: String? {
        get {
            return cdObject.longMessageFormatted
        }
        set {
            cdObject.longMessageFormatted = newValue
        }
    }

    public var sent: Date? {
        get {
            return cdObject.sent
        }
        set {
            cdObject.sent = newValue
        }
    }

    public var from: Identity? {
        get {
            guard let cdFrom = cdObject.from else {
                return nil
            }
            return Identity(cdObject: cdFrom, context: moc)
        }
        set {
            cdObject.from = newValue?.cdObject
        }
    }

    /** See the extension for it (in the app), for more type-safety */
    //!!!: use it here?! (the extension). Also rethink, check what we have (enum exists?) and maybe renam pEpRating to pEpRatingRawValue in MOM
    public var pEpRatingInt: Int {
        get {
            return Int(cdObject.pEpRating)
        }
        set { //!!!: should not be set-able. 
            cdObject.pEpRating = Int16(newValue)
        }
    }

    ///Shadows the `uuid`.
    public var messageID: MessageID {
        get {
            return uuid
        }
        set {
            uuid = newValue
        }
    }

    /// An identifier for that message.
    ///
    /// - note: The UID for a message (together with the unique identifier validity) is only unique
    ///         within the folder it is contained, so the folder UID would be needed
    ///         to uniquely refer to it (see https://tools.ietf.org/html/rfc3501#section-2.3.1.1 ).
    public private(set) var uid: Int {
        get {
            return Int(cdObject.uid)
        }
        set {
            cdObject.uid = Int32(newValue)
        }
    }

    /**
     Set to `false` to send out unprotected.
     */
    public var pEpProtected: Bool {
        get {
            return cdObject.pEpProtected
        }
        set {
            cdObject.pEpProtected = newValue
        }
    }

    // MARK: - To many relationships

    // MARK: optionalFields

    //!!!: tripple check which append/remove/replace we really need! Assume none given a proper init for outgoin messages

    //!!!: make it an MessageModelObject (HeaderField)
    public var optionalFields: [String:String] {
        get {
            var headers = [String:String]()
            guard let cdHeaders = cdObject.optionalFields?.array as? [CdHeaderField] else {
                return headers
            }
            for cdHeader in cdHeaders {
                headers[cdHeader.name!] = cdHeader.value!
            }
            return headers
        }
    }

    public func addToOptionalFields(key: String, value: String) {
        let result =
            (cdObject.optionalFields?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()

        // Find existing field for key ...
        let existingForKey =
            cdObject.optionalFields?.filter { ($0 as! CdHeaderField).name == key } ?? []
        if existingForKey.count > 1 {
            // ... assure we have max one ...
            Log.shared.errorAndCrash("Invalid state. More than one field for key %@", key)
        }
        if let existing = existingForKey.first as? CdHeaderField {
            // ... and delete it.
            moc.delete(existing)
        }
        let cdElement = CdHeaderField(context: moc)
        cdElement.name = key
        cdElement.value = value
        result.insert(cdElement, at: result.count)
        cdObject.optionalFields = result
    }

    // MARK: Attachments

    public var attachments: UnappendableArray<Attachment> {
        get {
            let cdRelationshipObjects = cdObject.attachments?.array as? [CdAttachment] ?? []
            let relationshipObjects = cdRelationshipObjects.map { Attachment(cdObject: $0, context: moc) }
            return UnappendableArray<Attachment>(array: relationshipObjects)
        }
    }

    //!!!: all replace can probaply be removed when introducing Outgoing message (by one init)
    public func replaceAttachments(with elements: [Attachment]) {
        // Delete orphaned, cascade rule does not remove it for some reason
        if let oldAttachments = cdObject.attachments?.array as? [CdAttachment] {
            for old in oldAttachments {
                moc.delete(old)
            }
        }
        cdObject.attachments = nil
        appendToAttachments(elements)
    }

    public func appendToAttachments(_ element: Attachment) {
        appendToAttachments([element])
    }

    public func appendToAttachments(_ elements: [Attachment]) {
        let result =
            (cdObject.attachments?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()
        for element in elements {
            result.insert(element.cdObject, at: result.count)
            element.cdObject.message = cdObject
        }
        cdObject.attachments = result
    }

    public func removeFromAttachments(_ element: Attachment) {
        let result =
            (cdObject.attachments?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()
        result.remove(element.cdObject)
        element.moc.delete(element.cdObject)
        cdObject.attachments = result
    }

    // MARK: To:

    public var to: UnappendableArray<Identity> {
        get {
            let relationshipObjects = identities(from: cdObject.to)
            return UnappendableArray<Identity>(array: relationshipObjects)
        }
    }

    public func replaceTo(with elements: [Identity]) {
        cdObject.to = nil
        appendToTo(elements)
    }

    public func appendToTo(_ element: Identity) {
        appendToTo([element])
    }

    public func appendToTo(_ elements: [Identity]) {
        let result =
            (cdObject.to?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()
        for element in elements {
            let cdElement = element.cdObject
            result.insert(cdElement, at: result.count)
        }
        cdObject.to = result
    }

    public func removeFromTo(_ element: Identity) {
        let result =
            (cdObject.to?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()
        result.remove(element.cdObject)
        cdObject.to = result
    }

    // MARK: CC

    public var cc: UnappendableArray<Identity> {
        get {
            let relationshipObjects = identities(from: cdObject.cc)
            return UnappendableArray<Identity>(array: relationshipObjects)
        }
    }

    public func replaceCc(with elements: [Identity]) {
        cdObject.cc = nil
        appendToCc(elements)
    }

    public func appendToCc(_ element: Identity) {
        appendToCc([element])
    }

    public func appendToCc(_ elements: [Identity]) {
        let result =
            (cdObject.cc?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()
        for element in elements {
            let cdElement = element.cdObject
            result.insert(cdElement, at: result.count)
        }
        cdObject.cc = result
    }

    // MARK: - BCC

    public var bcc: UnappendableArray<Identity> {
        get {
            let relationshipObjects = identities(from: cdObject.bcc)
            return UnappendableArray<Identity>(array: relationshipObjects)
        }
    }

    public func replaceBcc(with elements: [Identity]) {
        cdObject.bcc = nil
        appendToBcc(elements)
    }

    public func appendToBcc(_ element: Identity) {
        appendToBcc([element])
    }

    public func appendToBcc(_ elements: [Identity]) {
        let result =
            (cdObject.bcc?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()
        for element in elements {
            let cdElement = element.cdObject
            result.insert(cdElement, at: result.count)
        }
        cdObject.bcc = result
    }

    public func removeFromBcc(_ element: Identity) {
        let result =
            (cdObject.bcc?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet()
        result.remove(element.cdObject)
        cdObject.bcc = result
    }
}

// MARK: - Fetching
//!!!: extract
extension Message {

    public static func by(uid: Int,
                          uuid: MessageID,
                          folderName: String,
                          accountAddress: String,
                          session: Session = Session.main) -> Message? {
        guard let account = Account.by(address: accountAddress) else {
            Log.shared.error("no account by email %@", accountAddress)
            return nil
        }
        let cdAccount = account.cdAccount()
        guard let cdMessage = CdMessage.search(uid: Int32(uid),
                                               uuid: uuid,
                                               folderName: folderName,
                                               inAccount: cdAccount,
                                               context: session.moc)
            else {
                return nil
        }
        return MessageModelObjectUtils.getMessage(fromCdMessage: cdMessage)
    }
}

// MARK: - Utils

extension Message {

    //!!!: looks like useful utils, but should go to own file. And probably to App targett. Tripple check
    public var allRecipients: Set<Identity> {
        var recipients = Set<Identity>()
        recipients = recipients.union(to)
        recipients = recipients.union(cc)
        recipients = recipients.union(bcc)
        return recipients
    }

    /// Returns all the recipients, already deduped.
    //!!!: MARTIN: this might has to be removed when IOS-2541 is done as we won't need all recipients in a single collection.
    public var allRecipientsOrdered: [Identity] {
        let recipients = to.allObjects + cc.allObjects + bcc.allObjects
        return recipients.uniques
    }

    //MB:----- Refactor

    /// Returns the Tos recipients, already deduped.
    public var tos: [Identity] {
        return to.allObjects.uniques
    }

    /// Returns the CCs recipients, already deduped.
    public var ccs: [Identity] {
        return cc.allObjects.uniques
    }

    /// Returns the BCCs recipients, already deduped.
    public var bccs: [Identity] {
        return bcc.allObjects.uniques
    }

    //------

    public var allIdentities: Set<Identity> {
        var recipients = allRecipients
        if let fro = from {
            recipients.insert(fro)
        }
        return recipients
    }
}

//!!!: extract

// MARK: - IMAP flags

extension Message {
    /**
     Marks the message as read, which in IMAP terms is called "seen".
     */
    public func markAsSeen() {
        // Set imap on the messageto  trigger FetchedResultsController change
        let imap = imapFlags
        guard !imap.seen else {
            // The message is marked as seen already. Thus there is nothing to do here.
            // This ways we also avoid potentionally triggering a message change.
            return
        }
        imap.seen = true
        imapFlags = imap
        moc.saveAndLogErrors()
    }
}

// MARK: - Custom{Debug}StringConvertible

extension Message: CustomDebugStringConvertible {
    public var debugDescription: String {
        let theSent = sent?.description ?? "nil"
        let theFrom = from?.description ?? "nil"
        let theShortMessage = shortMessage ?? "nil"
        return "<Message \"\(uuid)\" \"\(parent.name)\" \(theSent) \"\(theShortMessage)\" from \(theFrom)>"
    }
}

extension Message: CustomStringConvertible {
    public var description: String {
        return debugDescription
    }
}

public enum Headers: String {

    case originalRating = "X-EncStatus"
}

//???: Should be extension to CdObject and forward?
// MARK: - Hashable

extension Message: Hashable {
    public func hash(into hasher: inout Hasher) {
        cdObject.hash(into: &hasher)
    }
}

//???: Should be extension to CdObject and forward?
// MARK: - Equatable

extension Message: Equatable {

    public static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Helper

extension Message {

    private func identities(from cdIdentities: NSOrderedSet?) -> [Identity] {
        guard let safeCdIdentities = cdIdentities?.array as? [CdIdentity] else {
            return []
        }

        let result: [Identity] =
            safeCdIdentities.compactMap { Identity(cdObject: $0, context: moc) }

        return result
    }
}
