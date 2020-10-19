//
//  SendMailHelper.swift
//  pEp-share
//
//  Created by Adam Kowalski on 18/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import PantomimeFramework
import PEPObjCAdapterFramework

final class SendMailHelper {

    static let shared = SendMailHelper()

    let smtpConnection: SmtpConnectAndSendMessage

    let accountAddress = "something@peptest.ch"
    let isClientCertificateSet = false
    let connectionTransport = ConnectionTransport.startTLS
    let serverAddress = "mail.peptest.ch"
    let serverPort: UInt32 = 587
    let loginName = "something@peptest.ch"
    let loginPassword = "password"

    private init() {
        smtpConnection = SmtpConnectAndSendMessage(accountAddress: accountAddress,
                                            connectionTransport: connectionTransport,
                                            serverAddress: serverAddress,
                                            serverPort: serverPort,
                                            loginName: loginName,
                                            loginPassword: loginPassword)
    }

    public func sendMessage() {
        let cwMsg = CWIMAPMessage(pEpMessage: testMessage(),
                                  mailboxName: "OUTBOX")
        smtpConnection.setMessage(cwMsg)
        smtpConnection.start()
    }

    private func testMessage() -> PEPMessage {
        let pEpMsg = PEPMessage()
        pEpMsg.from = PEPIdentity(address: accountAddress)
        pEpMsg.direction = .outgoing
        pEpMsg.to = [PEPIdentity(address: accountAddress)]
//        pEpMsg.sentDate = Date()
        pEpMsg.inReplyTo = [accountAddress]
        pEpMsg.longMessage = "long message"
        pEpMsg.messageID = "1"
        pEpMsg.shortMessage = "test e-mail sent from fantom..."

        return pEpMsg
    }
}
