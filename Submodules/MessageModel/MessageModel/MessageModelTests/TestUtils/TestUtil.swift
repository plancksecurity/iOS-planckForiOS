//
//  TestUtil.swift
//  MessageModel
//
//  Created by Xavier Algarra on 02/12/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//


import CoreData
import XCTest

@testable import MessageModel
import PEPObjCAdapterFramework
import pEpIOSToolbox

class TestUtil {
    
    /**
     The maximum time most test are allowed to run.
     */
    static let waitTime: TimeInterval = 30

    // MARK: - Messages & Attachments

    static public func createMessage(stringData: String = "test",
                                     numAttachments num: Int) -> Message {
        let createe = Message.fakeMessage(uuid: "\(stringData)")
        createe.shortMessage = "s\(stringData)"
        createe.longMessage = "l\(stringData)"
        let attachments = createAttachments(numAttachments: num)
        createe.appendToAttachments(attachments)

        return createe
    }

    static public func createAttachments(numAttachments num: Int) -> [Attachment] {
        var createes = [Attachment]()
        if num <= 0 {
            return createes
        }
        for i in 1...num {
            let createe = createAttachmentNamed(filename: "\(i)")
            createes.append(createe)

        }
        return createes
    }

    static public func createAttachmentNamed(filename: String = "testName") -> Attachment {
        let createe = Attachment(data: nil, mimeType: "", fileName: "\(filename)")
        return createe
    }
}

//!!!: refactor
// MARK: - MUST NOT use MM's Interface. MAY use Secret test data after moving

extension TestUtil {

    static public func createMessages(numMessages numM: Int,
                                      outgoing: Bool = false,
                                      moc: NSManagedObjectContext) -> [CdMessage] {
        var createes = [CdMessage]()
        if numM <= 0 {
            return createes
        }
        for i in 1...numM {
            let createe = createMessage(stringData: "stringData \(i)", outgoing: outgoing, moc: moc)
            createes.append(createe)
        }

        return createes
    }

    static public func createMessage(stringData: String = "test",
                                     sentDate: Date? = nil,
                                     outgoing: Bool = false,
                                     moc: NSManagedObjectContext) -> CdMessage {
        let account = createFakeAccount(moc: moc)

        let createe = CdMessage(context: moc)
        createe.uuid = UUID().uuidString + stringData
        createe.shortMessage = stringData
        createe.longMessage = stringData
        createe.longMessageFormatted = stringData
        createe.sent = sentDate ?? (Date().addingTimeInterval(1.0))
        let communicationPartner = createIdentity(idAddress: "someone@else.where",
                                                  idUserName: "someone@else.where",
                                                  userID: "someone@else.where",
                                                  moc: moc)
        let me = account.identity!
        if outgoing {
            createe.from = me
            createe.addToTo(communicationPartner)
            createe.parent = createFolder(name: "Sent", folderType: .sent, moc: moc)
        } else {
            createe.from = communicationPartner
            createe.addToTo(me)
            let inbox = account.folders!.firstObject! as! CdFolder
            assert(inbox.folderType == .inbox)
            createe.parent = inbox
        }

        return createe
    }

    static func createCdMessages(numMessages: Int,
                                 cdFolder: CdFolder,
                                 moc: NSManagedObjectContext) -> [CdMessage] {
        var newMessages = [CdMessage]()
        for i in 0..<numMessages {
            let newMessage = createCdMessage(withText: "test \(i)", cdFolder: cdFolder, moc: moc)
            newMessages.append(newMessage)
        }
        return newMessages
    }

    @discardableResult
    static func createCdMessage(withText text: String = "test",
                                sentDate: Date? = nil,
                                cdFolder: CdFolder,
                                moc: NSManagedObjectContext) -> CdMessage {
        let newMessage = CdMessage(context: moc)
        newMessage.uuid = UUID().uuidString + text
        newMessage.shortMessage = text
        newMessage.longMessage = text
        newMessage.longMessageFormatted = text
        newMessage.sent = sentDate ?? (Date().addingTimeInterval(1.0))
        newMessage.parent = cdFolder
        guard let me = cdFolder.account?.identity else {fatalError("Account must have an Identity")}
        let communicationPartner = createIdentity(idAddress: "someone@else.where",
                                                  idUserName: "someone@else.where",
                                                  userID: "someone@else.where",
                                                  moc: moc)
        if cdFolder.folderType == .sent {
            newMessage.from = me
            newMessage.addToTo(communicationPartner)
        } else {
            newMessage.from = communicationPartner
            newMessage.addToTo(me)
        }

        return newMessage
    }

    static func createIdentity(idAddress: String = "me@me.me",
                               idUserName: String = "idUserName",
                               userID: String = UUID().uuidString,
                               moc: NSManagedObjectContext) -> CdIdentity {
        let createe = CdIdentity(context: moc)
        createe.address = idAddress
        createe.userName = idUserName
        createe.userID = userID

        return createe
    }

    static func createServer(serverPort: Int = 42,
                             serverAddress: String = "mail.fakeServer.fake",
                             serverTransport: Server.Transport = .startTls,
                             password: String = "fakePassword",
                             loginName: String = "fakeLoginName",
                             automaticallyTrusted: Bool = false,
                             manuallyTrusted: Bool = false,
                             serverType: Server.ServerType,
                             moc: NSManagedObjectContext) -> CdServer {
        //SMTP
        let createe = CdServer(context: moc)
        createe.serverType = serverType
        createe.port = Int16(serverPort)
        createe.address = serverAddress
        createe.transport = serverTransport
        createe.automaticallyTrusted = automaticallyTrusted
        createe.manuallyTrusted = manuallyTrusted

        let keychainKeySmtp = UUID().uuidString
        CdServerCredentials.add(password: password, forKey: keychainKeySmtp)
        let credSmtp = CdServerCredentials(context: moc)
        credSmtp.loginName = loginName
        credSmtp.key = keychainKeySmtp
        createe.credentials = credSmtp

        return createe
    }

    static func createFolder(name: String = "INBOX",
                             folderType: FolderType = .inbox,
                             moc: NSManagedObjectContext) -> CdFolder {
        let createe = CdFolder(context: moc)
        createe.name = name
        createe.folderType = folderType

        return createe
    }

    static func createFakeAccount(idAddress: String = "me@me.me",
                                  idUserName: String = "idUserName",
                                  userID: String = UUID().uuidString,

                                  smtpServerPort: Int = 23,
                                  smtpServerAddress: String = "mail.fakeServer.fake",
                                  smtpServerTransport: Server.Transport = .startTls,
                                  smtpPassword: String = "fakePassword",
                                  smtpLoginName: String? = nil,

                                  imapServerPort: Int = 23,
                                  imapServerAddress: String = "mail.fakeServer.fake",
                                  imapServerTransport: Server.Transport = .startTls,
                                  imapPassword: String = "fakePassword",
                                  imapLoginName: String? = nil,

                                  inboxFolder: CdFolder? = nil,

                                  moc: NSManagedObjectContext) -> CdAccount {

        let acc = CdAccount(context: moc)
        acc.identity = createIdentity(idAddress: idAddress,
                                      idUserName: idUserName,
                                      userID: userID,
                                      moc: moc)

        //SMTP
        let smtp = createServer(serverPort: smtpServerPort,
                                serverAddress: smtpServerAddress,
                                serverTransport: smtpServerTransport,
                                password: smtpPassword,
                                loginName: smtpLoginName ?? idAddress,
                                serverType: .smtp,
                                moc: moc)
        acc.addToServers(smtp)

        //IMAP
        let imap = createServer(serverPort: imapServerPort,
                                serverAddress: imapServerAddress,
                                serverTransport: imapServerTransport,
                                password: imapPassword,
                                loginName: imapLoginName ?? idAddress,
                                serverType: .imap,
                                moc: moc)
        acc.addToServers(imap)

        // Inbox
        if let ib = inboxFolder {
            acc.addToFolders(ib)
        } else {
            let newInbox = createFolder(moc: moc)
            acc.addToFolders(newInbox)
        }

        return acc
    }

    // MARK: - Sync Loop

    static public func syncAndWait(cdAccountsToSync:[CdAccount]? = nil,
                                   testCase: XCTestCase,
                                   context: NSManagedObjectContext? = nil) {

        let context: NSManagedObjectContext = context ?? Stack.shared.mainContext
        guard let accounts = cdAccountsToSync ?? CdAccount.all(in: context) as? [CdAccount] else {
            XCTFail("No account to sync")
            return
        }
        // Serial queue
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let errorPropagator = ErrorPropagator()

        // Array to own services as long as they are in use.
        var services = [ServiceProtocol]()

        for cdaccount in accounts {
            // Send all
            guard let sendService = cdaccount.sendService(errorPropagator: errorPropagator) else {
                // This account does not offer a send send service. That might be a valid case for
                // protocols supported in the future.
                continue
            }
            services.append(sendService)
            queue.addOperations(sendService.operations(), waitUntilFinished: false)

            // Fetch & Sync all
            guard
                let replicationService = cdaccount.replicationService(errorPropagator: errorPropagator)
                else {
                // This account does not offer a replication send service. That might be a valid case for
                // protocols supported in the future.
                continue
            }
            services.append(replicationService)
            queue.addOperations(replicationService.operations(), waitUntilFinished: false)
        }

        // Decrypt all
        let decryptService = DecryptService(errorPropagator: errorPropagator)
        services.append(decryptService)
        queue.addOperations(decryptService.operations(), waitUntilFinished: false)


        let expSynced = testCase.expectation(description: "expSynced")
        DispatchQueue.global(qos: .utility).async {
            queue.waitUntilAllOperationsAreFinished()
            expSynced.fulfill()
        }

        testCase.wait(for: [expSynced], timeout: waitTime)
    }

    // MARK: - Moved from App target. Needs love, review, ideally remove

    static func makeFolderInteresting(folderType: FolderType,
                                      cdAccount: CdAccount,
                                      context: NSManagedObjectContext? = nil) {
        let folder = cdFolder(ofType: folderType, in: cdAccount, context: context)
        folder.lastLookedAt = Date(timeInterval: -1, since: Date())
        guard let context = cdAccount.managedObjectContext else {
            Log.shared.errorAndCrash("The account we are using has been deleted from moc!")
            return
        }
        context.saveAndLogErrors()
    }

    static func cdFolder(ofType type: FolderType,
                         in cdAccount: CdAccount,
                         context: NSManagedObjectContext? = nil) -> CdFolder {
        guard let folder = CdFolder.by(folderType: type, account: cdAccount, context: context)
            else {
                fatalError()
        }
        return folder
    }

    static func checkForExistanceAndUniqueness(uuids: [MessageID],
                                               context: NSManagedObjectContext) {
        for uuid in uuids {
            if let ms = CdMessage.all(attributes: ["uuid": uuid], in: context) as? [CdMessage] {
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

    static func setupSomePEPIdentities()
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

    static func loadString(fileName: String) -> String? {
        if let data = MiscUtil.loadData(bundleClass: self, fileName: fileName) {
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

    static func createCdAttachment(inlined: Bool = true) -> CdAttachment {
        let attachment = createAttachment(inlined: inlined)
        return attachment.cdObject
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
        guard let imageData = TestUtil.loadData(testClass: self, fileName: imageFileName) else {
            XCTAssertTrue(false)
            return Attachment(data: nil, mimeType: "meh", contentDisposition: .attachment)
        }

        let contentDisposition = inlined ? Attachment.ContentDispositionType.inline : .attachment

        return Attachment(data: imageData,
                          mimeType: MimeTypeUtils.MimeType.jpeg,
                          fileName: imageFileName,
                          contentDisposition: contentDisposition)
    }
}

//BUFF: move to own file

extension XCTestCase {
    public func loginIMAP(imapConnection: ImapConnectionProtocol,
                          errorContainer: ErrorContainerProtocol,
                          queue: OperationQueue,
                          context: NSManagedObjectContext? = nil) {
        let expImapLoggedIn = expectation(description: "expImapLoggedIn")

        let imapLogin = LoginImapOperation(parentName: #function,
                                           context: context,
                                           errorContainer: errorContainer,
                                           imapConnection: imapConnection)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            expImapLoggedIn.fulfill()
        }
        queue.addOperation(imapLogin)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors)
        })
    }

    public func fetchFoldersIMAP(imapConnection: ImapConnectionProtocol,
                                 queue: OperationQueue) {
        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                           imapConnection: imapConnection)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        queue.addOperation(syncFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(syncFoldersOp.hasErrors)
        })
    }

    //!!!: used in tests only! move to test target
    func appendMailsIMAP(folder: CdFolder,
                         imapConnection: ImapConnectionProtocol,
                         errorContainer: ErrorContainerProtocol,
                         queue: OperationQueue) {
        let expSentAppended = expectation(description: "expSentAppended")
        let appendOp = AppendMailsToFolderOperation(parentName: #function,
                                                    folder: folder,
                                                    errorContainer: errorContainer,
                                                    imapConnection: imapConnection)
        appendOp.completionBlock = {
            appendOp.completionBlock = nil
            expSentAppended.fulfill()
        }

        queue.addOperation(appendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(appendOp.hasErrors)
        })
    }

    public func fetchNumberOfNewMails(errorContainer: ErrorContainerProtocol,
                                      context: NSManagedObjectContext) -> Int? {
        let expNumMails = expectation(description: "expNumMails")
        var numMails: Int?
        let fetchNumMailsOp = FetchNumberOfNewMailsService(imapConnectionDataCache: nil,
                                                           context: context,
                                                           errorContainer: errorContainer)
        fetchNumMailsOp.start() { theNumMails in
            numMails = theNumMails
            expNumMails.fulfill()
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotNil(numMails)
            XCTAssertNil(errorContainer.error)
        })

        return numMails
    }
}
