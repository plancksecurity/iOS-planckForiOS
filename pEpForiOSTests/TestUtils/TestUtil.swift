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
            msg.session.commit()
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
        guard let imageData = MiscUtil.loadData(bundleClass: TestUtil.self,
                                                fileName: imageFileName) else {
                                                    XCTFail()
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
        msg.session.commit()

        return msg
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
}
