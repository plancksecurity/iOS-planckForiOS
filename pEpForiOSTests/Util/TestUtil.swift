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
     Assumed maximum time for our IMAP sync loop to reach IMAP IDLE mode
     */
    static let waitTimeIdleMode: TimeInterval = 10

    /**
     The time to wait for something "leuisurely".
     */
    static let waitTimeCoupleOfSeconds: TimeInterval = 2

    static let connectonShutDownWaitTime: TimeInterval = 1
    static let numberOfTriesConnectonShutDown = 5

    static var initialNumberOfRunningConnections = 0
    static var initialNumberOfServices = 0


    /// Waits without blocking.
    ///
    /// - Parameter seconds: wait time
    static func waitUnblocking(_ seconds: TimeInterval) {
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, seconds, false)
    }

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
    static func importKeyByFileName(_ session: PEPSession, fileName: String) {
        if let content = loadString(fileName: fileName) {
            session.importKey(content as String)
        }
    }

    static func setupSomeIdentities(_ session: PEPSession)
        -> (identity: NSMutableDictionary, receiver1: PEPIdentity,
        receiver2: PEPIdentity, receiver3: PEPIdentity,
        receiver4: PEPIdentity) {
            let identity = NSMutableDictionary()
            identity[kPepUsername] = "Unit Test"
            identity[kPepAddress] = "somewhere@overtherainbow.com"

            let receiver1 = NSMutableDictionary()
            receiver1[kPepUsername] = "receiver1"
            receiver1[kPepAddress] = "receiver1@shopsmart.com"

            let receiver2 = NSMutableDictionary()
            receiver2[kPepUsername] = "receiver2"
            receiver2[kPepAddress] = "receiver2@shopsmart.com"

            let receiver3 = NSMutableDictionary()
            receiver3[kPepUsername] = "receiver3"
            receiver3[kPepAddress] = "receiver3@shopsmart.com"

            let receiver4 = NSMutableDictionary()
            receiver4[kPepUsername] = "receiver4"
            receiver4[kPepAddress] = "receiver4@shopsmart.com"

            return (identity, receiver1 as NSDictionary as! PEPIdentity,
                    receiver2 as NSDictionary as! PEPIdentity,
                    receiver3 as NSDictionary as! PEPIdentity,
                    receiver4 as NSDictionary as! PEPIdentity)
    }

    /**
     Recursively removes some (not so important) keys from dictionaries
     so they don't interfere with `isEqual`.
     */
    static func removeUnneededKeysForComparison(
        _ keys: [String], fromMail: PEPMessage) -> PEPMessage {
        var m: [String: AnyObject] = fromMail
        for k in keys {
            m.removeValue(forKey: k)
        }
        let keysToCheckRecursively = m.keys
        for k in keysToCheckRecursively {
            let value = m[k]
            if let dict = value as? PEPMessage {
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

    static func checkForUniqueness(uuids: [MessageID]) {
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
                XCTFail()
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

    class FetchMessagesServiceTestDelegate: FetchMessagesServiceDelegate {
        var fetchedMessages = [Message]()

        func didFetch(message: Message) {
            fetchedMessages.append(message)
        }
    }

    static func runFetchTest(parentName: String, testCase: XCTestCase, cdAccount: CdAccount,
                             useDisfunctionalAccount: Bool,
                             folderName: String = ImapSync.defaultImapInboxName,
                             expectError: Bool) {
        if useDisfunctionalAccount {
            TestUtil.makeServersUnreachable(cdAccount: cdAccount)
        }

        guard let (imapSyncData, _) = TestUtil.syncData(cdAccount: cdAccount) else {
            XCTFail()
            return
        }

        let expectationServiceRan = testCase.expectation(description: "expectationServiceRan")
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expectationServiceRan)

        let service = FetchMessagesService(parentName: parentName, backgrounder: mbg,
                                           imapSyncData: imapSyncData, folderName: folderName)
        let testDelegate = FetchMessagesServiceTestDelegate()
        service.delegate = testDelegate

        let expServiceBlockInvoked = testCase.expectation(description: "expServiceBlockInvoked")
        service.execute() { error in
            expServiceBlockInvoked.fulfill()

            if expectError {
                XCTAssertNotNil(error)
            } else {
                XCTAssertNil(error)
            }
        }

        testCase.waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        if expectError {
            XCTAssertEqual(testDelegate.fetchedMessages.count, 0)
        } else {
            XCTAssertGreaterThan(testDelegate.fetchedMessages.count, 0)
        }

        imapSyncData.sync?.close()
    }

    // MARK: - Send Emails

    static func sendMailsToYourselfAndWait(cdAccount: CdAccount, expectation: XCTestExpectation, numMails: Int = 1, addAttachment: Bool = false) {
        if numMails <= 0 {
            return
        }
        let outgoingMailsToSend = TestUtil.createOutgoingMailsToYourselfAndWait(
            cdAccount: cdAccount, numMails: numMails, addAttachment: addAttachment)

        XCTAssertGreaterThan(outgoingMailsToSend.count, 0)

        guard let (imapSyncData, smtpSendData) = TestUtil.syncData(cdAccount: cdAccount) else {
            XCTFail()
            return
        }
        let backgrounder = MockBackgrounder()

        let smtpSentDelegate = TestSmtpSendServiceDelegate()
        let smtpService = SmtpSendService(
            parentName: #function, backgrounder: backgrounder,
            imapSyncData: imapSyncData, smtpSendData: smtpSendData)
        smtpService.delegate = smtpSentDelegate
        var smtpExecuted = false
        smtpService.execute() { error in
            if error == nil {
                XCTAssertEqual(smtpSentDelegate.successfullySentMessageIDs.count,
                               outgoingMailsToSend.count)
            } else {
                XCTAssertLessThan(smtpSentDelegate.successfullySentMessageIDs.count,
                                  outgoingMailsToSend.count)
            }
            smtpExecuted = true
        }

        let timeoutTimer = Date()
        while !smtpExecuted {
            TestUtil.waitUnblocking(0.001)
            if -timeoutTimer.timeIntervalSinceNow > TestUtil.waitTime{
                return
            }
        }

        expectation.fulfill()
    }

    // MARK: - Attachments

    static func createMails(in folder: CdFolder, from: CdIdentity, to: CdIdentity, numMails: Int = 1,
                            addAttachment: Bool = false) -> [CdMessage] {
        var messages = [CdMessage]()
        if numMails <= 0 {
            return messages
        }

        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard let imageData = TestUtil.loadData(fileName: imageFileName) else {
            XCTAssertTrue(false)
            return []
        }

        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sent = Date() as NSDate
            message.addTo(cdIdentity: to)

            if addAttachment {
                let attachment = Attachment.create(data: imageData, mimeType: "image/jpeg",
                                                   fileName: "\(imageFileName) \(i)")
                let cdAttachment = CdAttachment.create(attachment: attachment)
                message.addAttachment(cdAttachment)
            }

            messages.append(message)
        }
        Record.saveAndWait()

        return messages
    }

    // MARK: - IMAP IDLE

    /// Waits until a potetiolly IMAP IDLE supporting server is in idle mode and sends an email 
    /// to trigger IDLE-new-message response from server.
    ///
    /// - Parameters:
    ///   - cdAccount: account to send email to
    ///   - expectation: is fullfilled when the server should have responded with IDLE-new-message
    static public func triggerImapIdleNewMessage(cdAccount: CdAccount, expectation: XCTestExpectation) {
        // As the server might support IMAP IDLE, we wait to assure
        // NetworlService's sync loop is ideling before we ...
        waitUntilInIdleMode()
        // ... send an email to trigger IDLE-new-message response from server.
        sendMailsToYourselfAndWait(cdAccount: cdAccount, expectation: expectation)
    }

    /// Waits until IMAP IDLE mode should be reached, if the server supports it
    static private func waitUntilInIdleMode() {
        TestUtil.waitUnblocking(TestUtil.waitTimeIdleMode)
    }

    /// Sends an email to yourself and waits until server changes should have been reported by a server, that is p
    static private func sendMailToYourselfAndWaitForImapIdleNewMessage(cdAccount: CdAccount, expectation: XCTestExpectation) {
        // As the server might support IMAP IDLE, we wait to assure
        // NetworlService's sync loop is ideling before we ...
        TestUtil.waitUnblocking(TestUtil.waitTimeIdleMode)
        // ... send an email to trigger IDLE-new-message response from server.

        TestUtil.sendMailsToYourselfAndWait(cdAccount: cdAccount, expectation: expectation)
    }

    // MARK: - Outgoing Mails

    @discardableResult static func
        createOutgoingMailsToYourselfAndWait(cdAccount: CdAccount,
                                             numMails: Int = 1,
                                             addAttachment: Bool = false) -> [CdMessage] {
        if numMails <= 0 {
            return []
        }

        let existingSentFolder = CdFolder.by(folderType: .sent, account: cdAccount)

        if existingSentFolder == nil {
            var foldersFetched = false
            guard let imapCI = cdAccount.imapConnectInfo else {
                XCTFail()
                return []
            }
            let imapSyncData = ImapSyncData(connectInfo: imapCI)
            let fs = FetchFoldersService(parentName: #function, imapSyncData: imapSyncData)
            fs.execute() { error in
                XCTAssertNil(error)
                foldersFetched = true
            }

            let timeoutTimer = Date()
            while !foldersFetched {
                TestUtil.waitUnblocking(0.001)
                if -timeoutTimer.timeIntervalSinceNow > TestUtil.waitTime{
                    return []
                }
            }
        }
        guard let sentFolder = CdFolder.by(folderType: .sent, account: cdAccount) else {
            XCTFail()
            return []
        }
        let from = cdAccount.identity ?? CdIdentity.create()
        from.userName = cdAccount.identity?.userName ?? "Unknown ?"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = cdAccount.identity ?? CdIdentity.create()
        to.userName = cdAccount.identity?.userName ?? "Unknown ?"
        to.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        var messages = TestUtil.createMails(in: sentFolder, from: from, to: to,
                                            addAttachment: addAttachment)

        if let cdOutgoingMsgs = sentFolder.messages?.sortedArray(
            using: [NSSortDescriptor.init(key: "uid", ascending: true)]) as? [CdMessage] {
            XCTAssertEqual(cdOutgoingMsgs.count, numMails)
            for m in cdOutgoingMsgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.sent)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, SendStatus.none)
            }
        } else {
            XCTFail()
        }

        return messages
    }

    static func createOutgoingMails(cdAccount: CdAccount, testCase: XCTestCase,
                                    numberOfMails: Int) -> [CdMessage] {
        testCase.continueAfterFailure = false

        if numberOfMails == 0 {
            return []
        }

        if numberOfMails < 3 {
            XCTFail("need 0 or at least 3 outgoing mails to generate")
            return []
        }

        let existingSentFolder = CdFolder.by(folderType: .sent, account: cdAccount)

        if existingSentFolder == nil {
            let expectationFoldersFetched = testCase.expectation(
                description: "expectationFoldersFetched")
            guard let imapCI = cdAccount.imapConnectInfo else {
                XCTFail()
                return []
            }
            let imapSyncData = ImapSyncData(connectInfo: imapCI)
            let fs = FetchFoldersService(parentName: #function, imapSyncData: imapSyncData)
            fs.execute() { error in
                XCTAssertNil(error)
                expectationFoldersFetched.fulfill()
            }

            testCase.wait(for: [expectationFoldersFetched], timeout: waitTime)
        }

        guard let sentFolder = CdFolder.by(folderType: .sent, account: cdAccount) else {
            XCTFail()
            return []
        }

        let session = PEPSession()
        TestUtil.importKeyByFileName(
            session, fileName: "Unit 1 unittest.ios.1@peptest.ch (0x9CB8DBCC) pub.asc")

        let from = CdIdentity.create()
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

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
            message.sent = Date() as NSDate
            message.addTo(cdIdentity: toWithKey)

            // add attachment to last and previous-to-last mail
            if i == numberOfMails || i == numberOfMails - 1 {
                let attachment = Attachment.create(
                    data: imageData, mimeType: "image/jpeg", fileName: imageFileName)
                let cdAttachment = CdAttachment.create(attachment: attachment)
                message.addAttachment(cdAttachment)
            }
            // prevent encryption for last mail
            if i == numberOfMails {
                message.bcc = NSOrderedSet(object: toWithoutKey)
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
}
