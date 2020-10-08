//
//  TestUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel
import pEpIOSToolbox
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

    //!!!: duplicated MM. Move to toolbox
    static func loadData(fileName: String) -> Data? {
        let testBundle = Bundle(for: self)
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
        guard let context = cdAccount.managedObjectContext else {
            Log.shared.errorAndCrash("The account we are using has been deleted from moc!")
            return
        }
        context.saveAndLogErrors()
    }

    // MARK: - Sync Loop

    static public func syncAndWait(numAccountsToSync: Int = 1, testCase: XCTestCase) {
        //BUFF: Is implemented in MM TestUtils. How can we get it here too? Do we need it at all (think yes)
    }

    // MARK: - Messages

    @discardableResult static func createMessages(number: Int,
                                                  engineProccesed: Bool = true,
                                                  inFolder: Folder,
                                                  setUids: Bool = true) -> [Message] {
        var messages : [Message] = []
        for i in 1...number {
            let uid = setUids ? i : nil

            let msg = createMessage(inFolder: inFolder,
                                    from: Identity(address: "mail@mail.com"),
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
        let msg : Message
        if let uid = uid {
            msg = Message(uuid: UUID().uuidString, uid: uid, parentFolder: folder)
        } else {
            msg = Message(uuid: UUID().uuidString, parentFolder: folder)
        }
        msg.from = from
        msg.replaceTo(with: tos)
        msg.replaceCc(with: ccs)
        msg.replaceBcc(with: bccs)
        msg.messageID = UUID().uuidString
        msg.shortMessage = shortMessage
        msg.longMessage = longMessage
        msg.longMessageFormatted = longMessageFormatted
        msg.sent = dateSent
        if engineProccesed {
            msg.pEpRatingInt = Int(PEPRating.unreliable.rawValue)
        }
        msg.replaceAttachments(with: createAttachments(number: attachments))
        return msg
    }

    static func createMessage(uid: Int, inFolder folder: Folder) -> Message {
        let msg = Message(uuid: "\(uid)", uid: uid, parentFolder: folder)
        XCTAssertEqual(msg.uid, uid)
        msg.pEpRatingInt = Int(PEPRating.unreliable.rawValue)
        return msg
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

        return Attachment(data: imageData,
                          mimeType: MimeTypeUtils.MimeType.jpeg.rawValue,
                          fileName: imageFileName,
                          contentDisposition: contentDisposition)
    }

    /// Creates one of 3 special messages that form a thread that caused some problems.
    static func createSpecialMessage(number: Int, folder: Folder, receiver: Identity) -> Message {

        struct Blueprint {
            let uuid: String
            let from: Identity
            let references: [String]
        }

        let blueprintData = [
            Blueprint(
                uuid: "ID1",
                from: Identity(address: "ar"),
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
                from: Identity(address: "ba"),
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
                from: Identity(address: "be"),
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
        msg.replaceTo(with: [receiver])
        msg.pEpRatingInt = Int(PEPRating.unreliable.rawValue)
        msg.sent = Date(timeIntervalSince1970: Double(number))
        msg.save()

        return msg
    }

    /// Determines the highest UID of _all_ the messages currently in the DB.
    static func highestUid(context: NSManagedObjectContext) -> Int {
        var theHighestUid: Int32 = 0
        if let allCdMessages = CdMessage.all(in: context) as? [CdMessage] {
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
    static func nextUid(context: NSManagedObjectContext) -> Int {
        return highestUid(context: context) + 1
    }

    // MARK: - SERVER

    static func setServersTrusted(forCdAccount cdAccount: CdAccount, testCase: XCTestCase) {
        guard let cdServers = cdAccount.servers?.allObjects as? [CdServer] else {
            XCTFail("No Servers")
            return
        }
        for server in cdServers {
            server.automaticallyTrusted = true
        }
        guard let context = cdAccount.managedObjectContext else {
            Log.shared.errorAndCrash("The account we are using has been deleted from moc!")
            return
        }
        context.saveAndLogErrors()
    }

    // MARK: - ERROR

    class TestErrorContainer: ErrorContainerProtocol { //!!!: rm. AFAICS the implementation is copy & pasted from ErrorContainer. If so, why not use ErrorContainer?
        var error: Error?

        func addError(_ error: Error) {
            if self.error == nil {
                self.error = error
            }
        }

        var hasErrors: Bool {
            return error != nil
        }

        func reset() {
            error = nil
        }
    }

    // MUST go to MM (used CDOs). Already adapts PP adapter when moved to MM (XCTest+SyncAdapter.swift)
    /**
     Does the following steps:

     * Loads an Email from the given path
     * Creates a self-Identity according to the receiver of the mail
     * Decrypts the mail, which should import the key

     After this function, you should have a self with generated key, and a partner ID
     you can do handshakes on.
     */
//    static func cdMessageAndSetUpPepFromMail(emailFilePath: String,
//                                             context: NSManagedObjectContext = Stack.shared.mainContext)
//        -> (mySelf: CdIdentity, partner: CdIdentity, message: CdMessage)? {
//            guard let pantomimeMail = cwImapMessage(fileName: emailFilePath) else {
//                XCTFail()
//                return nil
//            }
//
//            guard let recipients = pantomimeMail.recipients() as? [CWInternetAddress] else {
//                XCTFail("Expected array of recipients")
//                return nil
//            }
//            var mySelfIdentityOpt: CdIdentity?
//            for rec in recipients {
//                if rec.type() == .toRecipient {
//                    mySelfIdentityOpt = rec.cdIdentity(userID: CdIdentity.pEpOwnUserID, context: context)
//                }
//            }
//            guard let safeOptId = mySelfIdentityOpt else {
//                XCTFail("Could not derive own identity from message")
//                return nil
//            }
//
//            context.saveAndLogErrors()
//
//            let cdMySelfIdentity = safeOptId
//            XCTAssertNotNil(cdMySelfIdentity)
//
//            let cdMyAccount = CdAccount(context: context)
//            cdMyAccount.identity = cdMySelfIdentity
//
//            let cdInbox = CdFolder(context: context)
//            cdInbox.name = ImapConnection.defaultInboxName
//            cdInbox.account = cdMyAccount
//
//            guard let pantFrom = pantomimeMail.from() else {
//                XCTFail("Expected the mail to have a sender")
//                return nil
//            }
//            let partnerID = pantFrom.cdIdentity(userID: "THE PARTNER ID", context: context)
//
//            context.saveAndLogErrors()
//
//            let session = PEPSession()
//            var mySelfIdentity = cdMySelfIdentity.pEpIdentity()
//            mySelfIdentity = mySelf(for: mySelfIdentity)
//            try! session.mySelf(mySelfIdentity)
//            XCTAssertNotNil(mySelfIdentity.fingerPrint)
//            XCTAssertTrue(try! mySelfIdentity.isPEPUser(session).boolValue)
//
//            guard let cdMessage = CdMessage.insertOrUpdate(pantomimeMessage: pantomimeMail,
//                                                           account: cdMyAccount,
//                                                           messageUpdate: CWMessageUpdate(),
//                                                           context: context) else {
//                                                            XCTFail()
//                                                            return nil
//            }
//            XCTAssertEqual(cdMessage.pEpRating, Int16(PEPRating.undefined.rawValue))
//
//            guard let cdM = CdMessage.first(in: context) else {
//                XCTFail("Expected the one message in the DB that we imported")
//                return nil
//            }
//            XCTAssertEqual(cdM.messageID, pantomimeMail.messageID())
//
//            let errorContainer = TestErrorContainer()
//            let decOp = DecryptMessageOperation(cdMessageToDecryptObjectId: cdM.objectID,
//                                                errorContainer: errorContainer)
//
//            let bgQueue = OperationQueue()
//            bgQueue.addOperation(decOp)
//            bgQueue.waitUntilAllOperationsAreFinished()
//            XCTAssertFalse(errorContainer.hasErrors)
//
//            return (mySelf: cdMySelfIdentity, partner: partnerID, message: cdMessage)
//    }

//    /**
//     Uses 'cdMessageAndSetUpPepFromMail', but returns the message as 'Message'.
//     */
//    static func setUpPepFromMail(emailFilePath: String)
//        -> (mySelf: Identity, partner: Identity, message: Message)? {
//            guard
//                let (mySelfID, partnerID, cdMessage) =
//                cdMessageAndSetUpPepFromMail(emailFilePath: emailFilePath)
//                else {
//                    return nil
//            }
//            let mySelf = MessageModelObjectUtils.getIdentity(fromCdIdentity: mySelfID)
//            let partner = MessageModelObjectUtils.getIdentity(fromCdIdentity: partnerID)
//            let msg = MessageModelObjectUtils.getMessage(fromCdMessage: cdMessage)
//            return (mySelf: mySelf, partner: partner, message: msg)
//    }

    //!!!: only used by MessagePantomimeTests & CdMessage_PantomimeTest. Move to MM with those tests
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
        pantomimeMail?.setFolder(CWIMAPFolder(name: ImapConnection.defaultInboxName))

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

        let moc: NSManagedObjectContext = Stack.shared.mainContext
        guard let cdMessage = CdMessage.insertOrUpdate(pantomimeMessage: pantomimeMail,
                                                       account: cdOwnAccount,
                                                       messageUpdate: CWMessageUpdate(),
                                                       context: moc)
            else {
                XCTFail()
                return nil
        }
        XCTAssertEqual(cdMessage.pEpRating, Int16(PEPRating.undefined.rawValue))

        return cdMessage
    }

    static func replacedCRLFWithLF(data: Data) -> Data {
        let mData = NSMutableData(data: data)
        mData.replaceCRLFWithLF()
        return mData as Data
    }
}
