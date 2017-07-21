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
     In case there are other connections open, call this function before relying on
     `waitForConnectionShutdown` or `waitForServiceCleanup`
     */
    static func adjustBaseLevel() {
        initialNumberOfRunningConnections = CWTCPConnection.numberOfRunningConnections()
        initialNumberOfServices = Service.refCounter.refCount
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
     Waits and verifies that all service objects (IMAP, SMTP) are finished.
     */
    static func waitForServiceCleanup() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if Service.refCounter.refCount == initialNumberOfServices {
                break
            }
            Thread.sleep(forTimeInterval: connectonShutDownWaitTime)
        }
        // This only works if there are no accounts configured in the app.
        XCTAssertEqual(Service.refCounter.refCount, initialNumberOfServices)
    }

    /**
     Waits and verifies that all service objects are properly shutdown and cleaned up.
     */
    static func waitForServiceShutdown() {
        TestUtil.waitForConnectionShutdown()
        TestUtil.waitForServiceCleanup()
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
            for c in creds {
                guard let cred = c as? CdServerCredentials else {
                    XCTAssertTrue(false)
                    return
                }
                cred.needsVerification = false
            }
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

        guard let folder = CdFolder.by(folderType: .sent, account: cdAccount) else {
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
            message.parent = folder
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

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.sent.rawValue)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, Int16(SendStatus.none.rawValue))
            }
        } else {
            XCTFail()
        }

        return messagesInTheQueue
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
        let cdServers = cdAccount.cdServers() { server in
            return Int(server.serverType) == Server.ServerType.imap.rawValue ||
                Int(server.serverType) == Server.ServerType.smtp.rawValue
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
}
