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
@testable import MessageModel

class TestUtil {
    /**
     The maximum time most tests are allowed to run.
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
     Waits and verifies that all connection threads are finished.
     */
    static func waitForConnectionShutdown() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if CWTCPConnection.numberOfRunningConnections() == initialNumberOfRunningConnections {
                break
            }
            Thread.sleep(forTimeInterval: connectonShutDownWaitTime)
        }
        // This only works if there are no accounts configured in the app.
        XCTAssertEqual(CWTCPConnection.numberOfRunningConnections(),
                       initialNumberOfRunningConnections)
    }

    /**
     Some code for accessing `NSBundle`s from Swift.
     */
    static func showBundles() {
        for bundle in Bundle.allBundles {
            dumpBundle(bundle)
        }

        let testBundle = Bundle.init(for: PEPSessionTest.self)
        dumpBundle(testBundle)
    }

    /**
     Print some essential properties of a bundle to the console.
     */
    static func dumpBundle(_ bundle: Bundle) {
        print("bundle \(String(describing: bundle.bundleIdentifier)) \(bundle.bundlePath)")
    }

    static func loadData(fileName: String) -> Data? {
        let testBundle = Bundle.init(for: PEPSessionTest.self)
        guard let keyPath = testBundle.path(forResource: fileName, ofType: nil) else {
            XCTAssertTrue(false, "Could not find file named \(fileName)")
            return nil
        }
        guard let data = try? Data.init(contentsOf: URL(fileURLWithPath: keyPath)) else {
            XCTAssertTrue(false, "Could not load file named \(fileName)")
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

    /**
     Validates all servers and their credentials without actually validating them.
     */
    static func skipValidation() {
        guard let accs = CdAccount.all() as? [CdAccount] else {
            XCTAssertTrue(false)
            return
        }
        for acc in accs {
            acc.needsVerification = false
        }

        guard let servers = CdServer.all() as? [CdServer] else {
            XCTAssertTrue(false)
            return
        }
        for server in servers {
            guard let creds = server.credentials else {
                XCTAssertTrue(false)
                return
            }
            creds.needsVerification = false
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

    static public func syncAndWait(numAccountsToSync: Int = 1, testCase: XCTestCase, skipValidation: Bool) {
        let networkService = NetworkService()
        networkService.sleepTimeInSeconds = 0.1

        let expAccountsSynced = testCase.expectation(description: "allAccountsSynced")
        // A temp variable is necassary, since the networkServiceUnitTestDelegate is weak
        let del = NetworkServiceObserver(numAccountsToSync: numAccountsToSync,
                                         expAccountsSynced: expAccountsSynced,
                                         failOnError: true)

        networkService.unitTestDelegate = del

        if skipValidation {
            TestUtil.skipValidation()
        }
        Record.saveAndWait()

        networkService.start()

        let canTakeSomeTimeFactor = 3.0
        testCase.waitForExpectations(timeout: TestUtil.waitTime * canTakeSomeTimeFactor) { error in
            XCTAssertNil(error)
        }

        TestUtil.cancelNetworkService(networkService: networkService, testCase: testCase)
    }

    // MARK: - NetworkService
    static public func cancelNetworkService(networkService: NetworkService, testCase: XCTestCase) {
        let del = NetworkServiceObserver(
            expCanceled: testCase.expectation(description: "expCanceled"))
        networkService.unitTestDelegate = del
        networkService.cancel()

        // Wait for cancellation
        testCase.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    // MARK: Messages

    static func createOutgoingMails(cdAccount: CdAccount,
                                    testCase: XCTestCase,
                                    numberOfMails: Int,
                                    withAttachments: Bool = true,
                                    attachmentsInlined: Bool = false,
                                    encrypt: Bool = true) throws -> [CdMessage] {
        testCase.continueAfterFailure = false

        if numberOfMails == 0 {
            return []
        }

        let existingSentFolder = CdFolder.by(folderType: .sent, account: cdAccount)

        if existingSentFolder == nil {
            // Make sure folders are synced
            syncAndWait(testCase: testCase, skipValidation: true)
        }

        guard let sentFolder = CdFolder.by(folderType: .sent, account: cdAccount) else {
            XCTFail()
            return []
        }

        if encrypt {
            let session = PEPSession()
            try TestUtil.importKeyByFileName(
                session, fileName: "Unit 1 unittest.ios.1@peptest.ch (0x9CB8DBCC) pub.asc")
        }

        let from = CdIdentity.create()
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"
        guard let fromUserId = cdAccount.identity?.userID else {
            fatalError("No userId")
        }
        from.userID = fromUserId

        let toWithKey = CdIdentity.create()
        toWithKey.userName = "Unit 001"
        toWithKey.address = "unittest.ios.1@peptest.ch"

        let toWithoutKey = CdIdentity.create()
        toWithoutKey.userName = "Unit 002"
        toWithoutKey.address = "unittest.ios.2@peptest.ch"

        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard let imageData = TestUtil.loadData(fileName: imageFileName) else {
            XCTAssertTrue(false)
            return []
        }

        // Build emails
        var messagesInTheQueue = [CdMessage]()
        for i in 1...numberOfMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = sentFolder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            // Add some time difference recognised by Date().sort.
            // That makes it easier to misuse thoses mails for manual debugging.
            let sentTimeOffset = Double(i) - 1
            message.sent = Date().addingTimeInterval(sentTimeOffset)
            message.addTo(cdIdentity: toWithKey)

            // add attachments
            if withAttachments {
                let contentDisposition =
                    attachmentsInlined ? Attachment.ContentDispositionType.inline : .attachment
                let attachment = Attachment.create(data: imageData,
                                                   mimeType: MimeTypeUtil.jpegMimeType,
                                                   fileName: imageFileName,
                                                   contentDisposition: contentDisposition)
                let cdAttachment = CdAttachment.create(attachment: attachment)
                message.addAttachment(cdAttachment: cdAttachment)
            }

            messagesInTheQueue.append(message)
        }
        Record.saveAndWait()

        if let cdOutgoingMsgs = sentFolder.messages?.sortedArray(
            using: [NSSortDescriptor.init(key: "uid", ascending: true)]) as? [CdMessage] {
            XCTAssertEqual(cdOutgoingMsgs.count, numberOfMails)
            for m in cdOutgoingMsgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.sent)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, SendStatus.none)
            }
        } else {
            XCTFail()
        }
        
        return messagesInTheQueue
    }

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
    static func setUpPepFromMail(emailFilePath: String,
                                 decryptDelegate: DecryptMessagesOperationDelegateProtocol? = nil)
        -> (mySelf: Identity, partner: Identity, message: Message)? {
            guard let pantomimeMail = cwImapMessage(fileName: emailFilePath) else {
                XCTFail()
                return nil
            }

            guard let recipients = pantomimeMail.recipients() as? [CWInternetAddress] else {
                XCTFail("Expected array of recipients")
                return nil
            }
            var mySelfIdentityOpt: Identity?
            for rec in recipients {
                if rec.type() == .toRecipient {
                    mySelfIdentityOpt = rec.identity(userID: "!MYSELF!")
                }
            }
            guard let safeOptId = mySelfIdentityOpt else {
                XCTFail("Could not derive own identity from message")
                return nil
            }
            let mySelfID = Identity(identity: safeOptId, isMySelf: true)
            mySelfID.save()

            let cdMySelfIdentity = CdIdentity.search(identity: mySelfID)
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
            let partnerID = pantFrom.identity(userID: "THE PARTNER ID")
            partnerID.save()

            Record.saveAndWait()

            let session = PEPSession()
            let mySelfIdentity = mySelfID.pEpIdentity()
            try! session.mySelf(mySelfIdentity)
            XCTAssertNotNil(mySelfIdentity.fingerPrint)
            XCTAssertTrue(try! mySelfIdentity.isPEPUser(session).boolValue)

            guard let cdMessage = CdMessage.insertOrUpdate(
                pantomimeMessage: pantomimeMail, account: cdMyAccount,
                messageUpdate: CWMessageUpdate(),
                forceParseAttachments: true) else {
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

        guard let msg = cdMessage.message() else {
            XCTFail("Need to be able to convert the CdMessage into a Message")
            return nil
        }

        return (mySelf: mySelfID, partner: partnerID, message: msg)
    }

    /**
     Loads the given file by name and parses it into a pantomime message.
     */
    static func cwImapMessage(fileName: String) -> CWIMAPMessage? {
        guard
            let msgTxt = TestUtil.loadData(
                fileName: fileName)
            else {
                XCTFail()
                return nil
        }

        let pantomimeMail = CWIMAPMessage(data: msgTxt, charset: "UTF-8")
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
            messageUpdate: CWMessageUpdate(),
            forceParseAttachments: true) else {
                XCTFail()
                return nil
        }
        XCTAssertEqual(cdMessage.pEpRating, CdMessage.pEpRatingNone)

        return cdMessage
    }
}
