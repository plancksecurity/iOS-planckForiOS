//
//  TestUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

@testable import pEpForiOS
@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework
import PantomimeFramework

class TestUtil {
    /**
     The maximum time for tests that don't consume any remote service.
     */
    static let waitTimeLocal: TimeInterval = 3

    /**
     The maximum time most intergationtests are allowed to run.
     */
    static let waitTime: TimeInterval = 30

    /**
     The maximum time model save tests are allowed to run.
     */
    static let modelSaveWaitTime: TimeInterval = 6

    /**
     The maximum time.
     */
    static let waitTimeForever: TimeInterval = 20000

    /**
     The time to wait for something "leuisurely".
     */
    static let waitTimeCoupleOfSeconds: TimeInterval = 2

    static let connectonShutDownWaitTime: TimeInterval = 1
    static let numberOfTriesConnectonShutDown = 5

    static var initialNumberOfRunningConnections = 0
    static var initialNumberOfServices = 0

    /**
     Some code for accessing `NSBundle`s from Swift.
     */
    static func showBundles() {
        for bundle in Bundle.allBundles {
            dumpBundle(bundle)
        }

        let testBundle = Bundle(for: PEPSessionTest.self)
        dumpBundle(testBundle)
    }

    /**
     Print some essential properties of a bundle to the console.
     */
    static func dumpBundle(_ bundle: Bundle) {
        print("bundle \(String(describing: bundle.bundleIdentifier)) \(bundle.bundlePath)")
    }

    static func loadData(fileName: String) -> Data? {
        let testBundle = Bundle(for: PEPSessionTest.self)
        guard let keyPath = testBundle.path(forResource: fileName, ofType: nil) else {
            XCTFail("Could not find file named \(fileName)")
            return nil
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: keyPath)) else {
            XCTFail("Could not load file named \(fileName)")
            return nil
        }
        return data
    }

    static func loadString(fileName: String) -> String? {
        if let data = loadData(fileName: fileName) {
            guard let content = NSString(data: data, encoding: String.Encoding.ascii.rawValue)
                else {
                    XCTAssertTrue(
                        false, "Could not convert key with file name \(fileName) into data")
                    return nil
            }
            return content as String
        }
        return nil
    }

    /**
     Import a key with the given file name from our own test bundle.
     - Parameter session: The pEp session to import the key into.
     - Parameter fileName: The file name of the key (complete with extension)
     */
    static func importKeyByFileName(_ session: PEPSession = PEPSession(), fileName: String)
        throws {
            if let content = loadString(fileName: fileName) {
                try session.importKey(content as String)
            }
    }

    static func setupSomeIdentities(_ session: PEPSession = PEPSession())
        -> (identity: PEPIdentity, receiver1: PEPIdentity,
        receiver2: PEPIdentity, receiver3: PEPIdentity,
        receiver4: PEPIdentity) {
            let identity = PEPIdentity(address: "somewhere@overtherainbow.com",
                                       userID: CdIdentity.pEpOwnUserID,
                                       userName: "Unit Test",
                                       isOwn: true)

            let receiver1 = PEPIdentity(address: "receiver1@shopsmart.com",
                                        userID: UUID().uuidString,
                                        userName: "receiver1",
                                        isOwn: false)

            let receiver2 = PEPIdentity(address: "receiver2@shopsmart.com",
                                        userID:  UUID().uuidString,
                                        userName: "receiver2",
                                        isOwn: false)

            let receiver3 = PEPIdentity(address: "receiver3@shopsmart.com",
                                        userID:  UUID().uuidString,
                                        userName: "receiver3",
                                        isOwn: false)

            let receiver4 = PEPIdentity(address: "receiver4@shopsmart.com",
                                        userID:  UUID().uuidString,
                                        userName: "receiver4",
                                        isOwn: false)

            return (identity, receiver1, receiver2, receiver3, receiver4)
    }

    /**
     Recursively removes some (not so important) keys from dictionaries
     so they don't interfere with `isEqual`.
     */
    static func removeUnneededKeysForComparison(
        _ keys: [String], fromMail: PEPMessageDict) -> PEPMessageDict {
        var m: [String: AnyObject] = fromMail
        for k in keys {
            m.removeValue(forKey: k)
        }
        let keysToCheckRecursively = m.keys
        for k in keysToCheckRecursively {
            let value = m[k]
            if let dict = value as? PEPMessageDict {
                m[k] = removeUnneededKeysForComparison(keys, fromMail: dict) as AnyObject?
            }
        }
        return m
    }

    /**
     Dumps some diff between two NSDirectories to the console.
     */
    static func diffDictionaries(_ dict1: NSDictionary, dict2: NSDictionary) {
        for (k,v1) in dict1 {
            if let v2 = dict2[k as! NSCopying] {
                if !(v1 as AnyObject).isEqual(v2) {
                    print("Difference in '\(k)': '\(v2)' <-> '\(v1)'")
                }
            } else {
                print("Only in dict1: \(k)")
            }
        }
        for (k,_) in dict2 {
            if dict1[k as! NSCopying] == nil {
                print("Only in dict2: \(k)")
            }
        }
    }

    static func checkForExistanceAndUniqueness(uuids: [MessageID]) {
        for uuid in uuids {
            if let ms = CdMessage.all(attributes: ["uuid": uuid]) as? [CdMessage] {
                var folder: CdFolder? = nil
                // check if that message is either unique, or all copies are in different folders
                for m in ms {
                    if let forig = folder {
                        if let f = m.parent {
                            XCTAssertNotEqual(forig, f)
                            folder = f
                        } else {
                            XCTFail()
                        }
                    }
                }
            } else {
                XCTFail("no message with message ID \(uuid)")
            }
        }
    }

    static func syncData(cdAccount: CdAccount) -> (ImapSyncData, SmtpSendData)? {
        guard
            let imapCI = cdAccount.imapConnectInfo,
            let smtpCI = cdAccount.smtpConnectInfo else {
                XCTFail()
                return nil
        }
        return (ImapSyncData(connectInfo: imapCI), SmtpSendData(connectInfo: smtpCI))
    }

    /**
     Makes the servers for this account unreachable, for tests that expects failure.
     */
    static func makeServersUnreachable(cdAccount: CdAccount) {
        guard let cdServers = cdAccount.servers?.allObjects as? [CdServer] else {
            XCTFail()
            return
        }

        for cdServer in cdServers {
            cdServer.address = "localhost"
            cdServer.port = 2525
        }
        if let context = cdAccount.managedObjectContext {
            context.saveAndLogErrors()
        } else {
            Record.saveAndWait()
        }
    }

    // MARK: - Sync Loop

    static public func syncAndWait(numAccountsToSync: Int = 1, testCase: XCTestCase) {
        let replicationService = ReplicationService()
        replicationService.sleepTimeInSeconds = 0.1

        let expAccountsSynced = testCase.expectation(description: "allAccountsSynced")
        // A temp variable is necassary, since the replicationServiceUnitTestDelegate is weak
        let del = NetworkServiceObserver(numAccountsToSync: numAccountsToSync,
                                         expAccountsSynced: expAccountsSynced,
                                         failOnError: true)

        replicationService.unitTestDelegate = del
        replicationService.delegate = del
        replicationService.start()

        let canTakeSomeTimeFactor = 3.0
        testCase.waitForExpectations(timeout: TestUtil.waitTime * canTakeSomeTimeFactor) { error in
            XCTAssertNil(error)
        }

        TestUtil.cancelReplicationServiceAndWait(replicationService: replicationService, testCase: testCase)
    }

    // MARK: - ReplicationService
    static public func cancelReplicationServiceAndWait(replicationService: ReplicationService, testCase: XCTestCase) {
        let del = NetworkServiceObserver(
            expCanceled: testCase.expectation(description: "expCanceled"))
        replicationService.unitTestDelegate = del
        replicationService.delegate = del
        replicationService.cancel()

        // Wait for cancellation
        testCase.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    // MARK: - Messages

    /// Calls createOutgoingMails for Cd...Objcets. See docs there.
    static func createOutgoingMails(account: Account,
                                    fromIdentity: Identity? = nil,
                                    toIdentity: Identity? = nil,
                                    setSentTimeOffsetForManualOrdering: Bool = false,
                                    testCase: XCTestCase,
                                    numberOfMails: Int,
                                    withAttachments: Bool = true,
                                    attachmentsInlined: Bool = false,
                                    encrypt: Bool = true,
                                    forceUnencrypted: Bool = false) throws -> [Message] {
        guard
            let cdAccount = account.cdAccount(),
            let cdFromIdentity = fromIdentity?.cdIdentity(),
            let cdToIdentity = toIdentity?.cdIdentity()
            else {
                XCTFail("No account.")
                return []
        }

        let cdMessages = try createOutgoingMails(cdAccount: cdAccount,
                                                 fromIdentity: cdFromIdentity,
                                                 toIdentity: cdToIdentity,
                                                 setSentTimeOffsetForManualOrdering: setSentTimeOffsetForManualOrdering,
                                                 testCase: testCase,
                                                 numberOfMails: numberOfMails,
                                                 withAttachments: withAttachments,
                                                 attachmentsInlined: attachmentsInlined,
                                                 encrypt: encrypt,
                                                 forceUnencrypted: forceUnencrypted)
        return cdMessages.map { $0.message()! }
    }

    /// Creates outgoing messages
    ///
    /// - Parameters:
    ///   - cdAccount: account to send from. Is ignored if fromIdentity is not nil 
    ///   - fromIdentity: identity used as sender
    ///   - toIdentity: identity used as recipient
    ///   - setSentTimeOffsetForManualOrdering: Add some time difference to date sent tp be
    ///                                         recognised by Date().sort. That makes it easier to
    ///                                         misuse thoses mails for manual debugging.
    //
    ///   - testCase: the one to make fail
    ///   - numberOfMails: num mails to create
    ///   - withAttachments: Whether or not messages should contain attachments
    ///   - attachmentsInlined: Whether or not the attachments should be inlined
    ///   - encrypt: Whether or not to import a key for the receipient. Is ignored if `toIdentity`
    ///              is not nil
    ///   - forceUnencrypted: mark mails force unencrypted
    /// - Returns: created mails
    /// - Throws: error importing key
    static func createOutgoingMails(cdAccount: CdAccount,
                                    fromIdentity: CdIdentity? = nil,
                                    toIdentity: CdIdentity? = nil,
                                    setSentTimeOffsetForManualOrdering: Bool = false,
                                    testCase: XCTestCase,
                                    numberOfMails: Int,
                                    withAttachments: Bool = true,
                                    attachmentsInlined: Bool = false,
                                    encrypt: Bool = true,
                                    forceUnencrypted: Bool = false) throws -> [CdMessage] {
        let cdAccount = fromIdentity?.accounts?.allObjects.first as? CdAccount ?? cdAccount 
        testCase.continueAfterFailure = false

        if numberOfMails == 0 {
            return []
        }

        let existingSentFolder = CdFolder.by(folderType: .sent, account: cdAccount)

        if existingSentFolder == nil {
            // Make sure folders are synced
            syncAndWait(testCase: testCase)
        }

        guard let outbox = CdFolder.by(folderType: .outbox, account: cdAccount) else {
            XCTFail()
            return []
        }

        let from: CdIdentity
        if let fromIdentity = fromIdentity {
            from = fromIdentity
        } else {
            from = CdIdentity.create()
            from.userName = cdAccount.identity?.userName ?? "Unit 004"
            from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"
        }
        guard let fromUserId = cdAccount.identity?.userID else {
            fatalError("No userId")
        }
        from.userID = fromUserId

        let to: CdIdentity
        if let toIdentity = toIdentity {
            to = toIdentity
        } else {
            if encrypt {
                let session = PEPSession()
                try TestUtil.importKeyByFileName(
                    session, fileName: "Unit 1 unittest.ios.1@peptest.ch (0x9CB8DBCC) pub.asc")
            }
            let toWithKey = CdIdentity.create()
            toWithKey.userName = "Unit 001"
            toWithKey.address = "unittest.ios.1@peptest.ch"
            to = toWithKey
        }

        // Build emails
        var messagesInTheQueue = [CdMessage]()
        for i in 1...numberOfMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = outbox
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.pEpProtected = !forceUnencrypted
            if setSentTimeOffsetForManualOrdering {
                // Add some time difference recognised by Date().sort.
                // That makes it easier to misuse thoses mails for manual debugging.
                let sentTimeOffset = Double(i) - 1
                message.sent = Date().addingTimeInterval(sentTimeOffset)
            } else {
                message.sent = Date()
            }
            message.addToTo(to)

            // add attachments
            if withAttachments {
                message.addToAttachments(createCdAttachment(inlined: attachmentsInlined))
            }

            messagesInTheQueue.append(message)
        }
        Record.saveAndWait()

        if let cdOutgoingMsgs = outbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "uid", ascending: true)]) as? [CdMessage] {
            let unsent = cdOutgoingMsgs.filter { $0.uid == 0 }
            XCTAssertEqual(unsent.count, numberOfMails)
            for m in unsent {
                XCTAssertEqual(m.parent?.folderType, FolderType.outbox)
                XCTAssertEqual(m.uid, Int32(0))
            }
        } else {
            XCTFail()
        }
        
        return messagesInTheQueue
    }

    @discardableResult static func createMessages(number: Int,
                                    engineProccesed: Bool = true,
                                    inFolder: Folder,
                                    setUids: Bool = true) -> [Message]{
        var messages : [Message] = []
        for i in 1...number {
            let uid = setUids ? i : nil

            let msg = createMessage(inFolder: inFolder,
                                    from: Identity.create(address: "mail@mail.com"),
                                    tos: [inFolder.account.user],
                                    engineProccesed: engineProccesed,
                                    uid: uid)
            messages.append(msg)
            msg.save()
        }
        return messages
    }

    static func createMessage(inFolder folder: Folder,
                                   from: Identity,
                                   tos: [Identity] = [],
                                   ccs: [Identity] = [],
                                   bccs: [Identity] = [],
                                   engineProccesed: Bool = true,
                                   shortMessage: String = "",
                                   longMessage: String = "",
                                   longMessageFormatted: String = "",
                                   dateSent: Date = Date(),
                                   attachments: Int = 0,
                                   uid: Int? = nil) -> Message {
        let msg = Message(uuid: MessageID.generate(), parentFolder: folder)
        msg.from = from
        msg.to = tos
        msg.cc = ccs
        msg.bcc = bccs
        msg.messageID = MessageID.generate()
        msg.shortMessage = shortMessage
        msg.longMessage = longMessage
        msg.longMessageFormatted = longMessageFormatted
        let minute:TimeInterval = 60.0
        msg.sent = dateSent
        msg.received = Date(timeIntervalSinceNow: minute)
        if engineProccesed {
            msg.pEpRatingInt = Int(PEPRating.unreliable.rawValue)
        }
        msg.attachments = createAttachments(number: attachments)
        var result = msg
        if let uid = uid {
            result =  Message(uid: uid, message: msg)
        }
        return result
    }

    static func createMessage(uid: Int, inFolder folder: Folder) -> Message {
        let msg = Message(uuid: "\(uid)", uid: uid, parentFolder: folder)
        XCTAssertEqual(msg.uid, uid)
        msg.pEpRatingInt = Int(PEPRating.unreliable.rawValue)
        msg.received = Date(timeIntervalSince1970: Double(uid))
        msg.sent = msg.received
        return msg
    }

    static func createCdAttachment(inlined: Bool = true) -> CdAttachment {
        let attachment = createAttachment(inlined: inlined)
        return CdAttachment.create(attachment: attachment)
    }

    static func createAttachments(number: Int) -> [Attachment] {
        var attachments: [Attachment] = []

        for _ in 0..<number {
            attachments.append(createAttachment())
        }
        return attachments
    }

    static func createAttachment(inlined: Bool = true) -> Attachment {

        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard let imageData = TestUtil.loadData(fileName: imageFileName) else {
            XCTAssertTrue(false)
            return Attachment(data: nil, mimeType: "meh", contentDisposition: .attachment)
        }

        let contentDisposition = inlined ? Attachment.ContentDispositionType.inline : .attachment

        return Attachment.create(data: imageData,
                          mimeType: MimeTypeUtil.jpegMimeType,
                          fileName: imageFileName,
                          contentDisposition: contentDisposition)
    }

    /**
     Creates one of 3 special messages that form a thread that caused some problems.
     */
    static func createSpecialMessage(number: Int, folder: Folder, receiver: Identity) -> Message {
        struct Blueprint {
            let uuid: String
            let from: Identity
            let references: [String]
        }

        let blueprintData = [
            Blueprint(
                uuid: "ID1",
                from: Identity.create(address: "ar"),
                references: ["ID2",
                             "ID3",
                             "ID4",
                             "ID5",
                             "ID6",
                             "ID7",
                             "ID8",
                             "ID9",
                             "ID2"]),
            Blueprint(
                uuid: "ID10",
                from: Identity.create(address: "ba"),
                references: ["ID1",
                             "ID3",
                             "ID4",
                             "ID5",
                             "ID6",
                             "ID7",
                             "ID8",
                             "ID9",
                             "ID2",
                             "ID1"]),
            Blueprint(
                uuid: "ID11",
                from: Identity.create(address: "be"),
                references: ["ID9",
                             "ID3",
                             "ID4",
                             "ID5",
                             "ID6",
                             "ID7",
                             "ID8"])
        ]

        let blueprint = blueprintData[number]

        let msg = Message(uuid: blueprint.uuid,
                          uid: number + 1,
                          parentFolder: folder)
        msg.from = blueprint.from
        msg.to = [receiver]
        msg.pEpRatingInt = Int(PEPRating.unreliable.rawValue)
        msg.received = Date(timeIntervalSince1970: Double(number))
        msg.sent = msg.received
        msg.references = blueprint.references
        msg.save()

        return msg
    }

    /**
     Determines the highest UID of _all_ the messages currently in the DB.
     */
    static func highestUid() -> Int {
        var theHighestUid: Int32 = 0
        if let allCdMessages = CdMessage.all() as? [CdMessage] {
            for cdMsg in allCdMessages {
                if cdMsg.uid > theHighestUid {
                    theHighestUid = cdMsg.uid
                }
            }
        }
        return Int(theHighestUid)
    }

    /**
     - Returns: `highestUid()` + 1
     */
    static func nextUid() -> Int {
        return highestUid() + 1
    }

    // MARK: - FOLDER

    static func determineInterestingFolders(in cdAccount: CdAccount)
        -> [NetworkServiceWorker.FolderInfo] {
        let accountInfo = AccountConnectInfo(accountID: cdAccount.objectID)
        let dummyConfig = ReplicationService.ServiceConfig(sleepTimeInSeconds: 1,
                                                       parentName: #function,
                                                       mySelfer:
            DefaultMySelfer(parentName: #function,
                            backgrounder: nil),
                                                       backgrounder: nil,
                                                       errorPropagator: nil)
        let networkServiceWorker = NetworkServiceWorker(serviceConfig: dummyConfig,
                                                        imapConnectionDataCache: nil)
        return networkServiceWorker.determineInterestingFolders(accountInfo: accountInfo)
    }

    static func makeFolderInteresting(folderType: FolderType, cdAccount: CdAccount) {
        let folder = cdFolder(ofType: folderType, in: cdAccount)
        folder.lastLookedAt = Date(timeInterval: -1, since: Date())
        Record.saveAndWait()
    }

    static func cdFolder(ofType type: FolderType, in cdAccount: CdAccount) -> CdFolder {
        guard let folder = CdFolder.by(folderType: type, account: cdAccount, context: nil)
            else {
                fatalError()
        }
        return folder
    }

    // MARK: - SERVER

    static func setServersTrusted(forCdAccount cdAccount: CdAccount, testCase: XCTestCase) {
        guard let cdServers = cdAccount.servers?.allObjects as? [CdServer] else {
            XCTFail("No Servers")
            return
        }
        for server in cdServers {
            server.trusted = true
        }
        Record.saveAndWait()
    }

    // MARK: - ERROR

    class TestErrorContainer: ServiceErrorProtocol {
        var error: Error?

        func addError(_ error: Error) {
            if self.error == nil {
                self.error = error
            }
        }

        func hasErrors() -> Bool {
            return error != nil
        }
    }

    /**
     Does the following steps:

     * Loads an Email from the given path
     * Creates a self-Identity according to the receiver of the mail
     * Decrypts the mail, which should import the key

     After this function, you should have a self with generated key, and a partner ID
     you can do handshakes on.
     */
    static func cdMessageAndSetUpPepFromMail(emailFilePath: String,
                                 decryptDelegate: DecryptMessagesOperationDelegateProtocol? = nil)
        -> (mySelf: CdIdentity, partner: CdIdentity, message: CdMessage)? {
            guard let pantomimeMail = cwImapMessage(fileName: emailFilePath) else {
                XCTFail()
                return nil
            }

            guard let recipients = pantomimeMail.recipients() as? [CWInternetAddress] else {
                XCTFail("Expected array of recipients")
                return nil
            }
            var mySelfIdentityOpt: CdIdentity?
            for rec in recipients {
                if rec.type() == .toRecipient {
                    mySelfIdentityOpt = rec.cdIdentity(userID: "!MYSELF!")
                }
            }
            guard let safeOptId = mySelfIdentityOpt else {
                XCTFail("Could not derive own identity from message")
                return nil
            }

            Record.saveAndWait()

            let cdMySelfIdentity = safeOptId
            XCTAssertNotNil(cdMySelfIdentity)

            let cdMyAccount = CdAccount.create()
            cdMyAccount.identity = cdMySelfIdentity

            let cdInbox = CdFolder.create()
            cdInbox.name = ImapSync.defaultImapInboxName
            cdInbox.uuid = MessageID.generate()
            cdInbox.account = cdMyAccount

            guard let pantFrom = pantomimeMail.from() else {
                XCTFail("Expected the mail to have a sender")
                return nil
            }
            let partnerID = pantFrom.cdIdentity(userID: "THE PARTNER ID")

            Record.saveAndWait()

            let session = PEPSession()
            let mySelfIdentity = cdMySelfIdentity.pEpIdentity()
            try! session.mySelf(mySelfIdentity)
            XCTAssertNotNil(mySelfIdentity.fingerPrint)
            XCTAssertTrue(try! mySelfIdentity.isPEPUser(session).boolValue)

            guard let cdMessage = CdMessage.insertOrUpdate(
                pantomimeMessage: pantomimeMail, account: cdMyAccount,
                messageUpdate: CWMessageUpdate()) else {
                    XCTFail()
                    return nil
            }
            XCTAssertEqual(cdMessage.pEpRating, CdMessage.pEpRatingNone)

            guard let cdM = CdMessage.first() else {
                XCTFail("Expected the one message in the DB that we imported")
                return nil
            }
            XCTAssertEqual(cdM.messageID, pantomimeMail.messageID())

            let errorContainer = TestErrorContainer()
            let decOp = DecryptMessagesOperation(errorContainer: errorContainer)

            decOp.delegate = decryptDelegate ?? DecryptionAttemptCounterDelegate()

            let bgQueue = OperationQueue()
            bgQueue.addOperation(decOp)
            bgQueue.waitUntilAllOperationsAreFinished()
            XCTAssertFalse(errorContainer.hasErrors())

            if let ownDecryptDelegate = decOp.delegate as? DecryptionAttemptCounterDelegate {
                XCTAssertEqual(ownDecryptDelegate.numberOfMessageDecryptAttempts, 1)
            }

            return (mySelf: cdMySelfIdentity, partner: partnerID, message: cdMessage)
    }

    /**
     Uses 'cdMessageAndSetUpPepFromMail', but returns the message as 'Message'.
     */
    static func setUpPepFromMail(emailFilePath: String,
                                 decryptDelegate: DecryptMessagesOperationDelegateProtocol? = nil)
        -> (mySelf: Identity, partner: Identity, message: Message)? {
            if let (mySelfID, partnerID, message) = cdMessageAndSetUpPepFromMail(
                emailFilePath: emailFilePath, decryptDelegate: decryptDelegate),
                let msg = message.message(),
                let mySelf = mySelfID.identity(),
                let partner = partnerID.identity() {
                return (mySelf: mySelf, partner: partner, message: msg)
            }
            return nil
    }

    /**
     Loads the given file by name and parses it into a pantomime message.
     */
    static func cwImapMessage(fileName: String) -> CWIMAPMessage? {
        guard
            var msgTxtData = TestUtil.loadData(
                fileName: fileName)
            else {
                XCTFail()
                return nil
        }

        // This is what pantomime does with everything it receives
        msgTxtData = replacedCRLFWithLF(data: msgTxtData)

        let pantomimeMail = CWIMAPMessage(data: msgTxtData, charset: "UTF-8")
        pantomimeMail?.setUID(5) // some random UID out of nowhere
        pantomimeMail?.setFolder(CWIMAPFolder(name: ImapSync.defaultImapInboxName))

        return pantomimeMail
    }

    /**
     Loads the given file by name, parses it with pantomime and creates a CdMessage from it.
     */
    static func cdMessage(fileName: String, cdOwnAccount: CdAccount) -> CdMessage? {
        guard let pantomimeMail = cwImapMessage(fileName: fileName) else {
            XCTFail()
            return nil
        }

        guard let cdMessage = CdMessage.insertOrUpdate(
            pantomimeMessage: pantomimeMail, account: cdOwnAccount,
            messageUpdate: CWMessageUpdate()) else {
                XCTFail()
                return nil
        }
        XCTAssertEqual(cdMessage.pEpRating, CdMessage.pEpRatingNone)

        return cdMessage
    }

    static func replacedCRLFWithLF(data: Data) -> Data {
        let mData = NSMutableData(data: data)
        mData.replaceCRLFWithLF()
        return mData as Data
    }
}
