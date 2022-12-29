//
//  TestUtil.swift
//  MessageModel
//
//  Created by Xavier Algarra on 02/12/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//


import XCTest
import CoreData

@testable import MessageModel
import PEPObjCAdapter
import pEpIOSToolbox

class TestUtil {
    
    /**
     The maximum time most test are allowed to run.
     */
    static let waitTime: TimeInterval = 30

    /// The maximum time waiting for a local operation that is expected to go through very quickly.
    static let waitTimeLocal: TimeInterval = 5

    // MARK: - Messages & Attachments

    static public func createMessage(stringData: String = "test",
                                     numAttachments num: Int) -> Message {
        let createe = Message.createTestMessage(uuid: "\(stringData)")
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
        guard let me = cdFolder.account?.identity else {
            Log.shared.errorAndCrash("Account must have an Identity")
            return CdMessage(context: moc)
        }
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
        createe.port = Int32(serverPort)
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

    // MARK: - Moved from App target. Needs love, review, ideally remove

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

    static func createAttachment(inlined: Bool = true) -> Attachment {
        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard let imageData = TestUtil.loadData(testClass: self, fileName: imageFileName) else {
            XCTAssertTrue(false)
            return Attachment(data: nil, mimeType: "meh", contentDisposition: .attachment)
        }

        let contentDisposition = inlined ? Attachment.ContentDispositionType.inline : .attachment

        return Attachment(data: imageData,
                          mimeType: MimeTypeUtils.MimeType.jpeg.rawValue,
                          fileName: imageFileName,
                          contentDisposition: contentDisposition)
    }
}
