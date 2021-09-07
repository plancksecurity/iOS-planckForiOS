//
//  KeySyncService+PEPSendMessageDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS
import pEpIOSToolbox

extension KeySyncService: PEPSendMessageDelegate {

    func send(_ message: PEPMessage) -> PEPStatus {
        guard let address = message.from?.address else {
            return PEPStatus.illegalValue
        }

        var foundAccount = true
        var resultingStatus = PEPStatus.OK // Will be returned to the adapter/engine

        let moc = Stack.shared.newPrivateConcurrentContext
        moc.performAndWait {
            guard let cdFromAccount = CdAccount.by(address: address, context: moc) else {
                foundAccount = false
                return
            }

            // Gather all recipients into one array.
            var recipients = message.to ?? []
            recipients.append(contentsOf: message.cc ?? [])

            // For every recipient, try to look up the corresponding account.
            let recipientsAccounts = recipients.compactMap { CdAccount.by(address: $0.address,
                                                                          context: moc)
            }

            if recipientsAccounts.count == recipients.count {
                // all receivers are own accounts, we can append
                resultingStatus = sendWithAppend(moc: moc,
                                                 receivingAccounts: recipientsAccounts,
                                                 pEpMessage: message)
            } else {
                // at least one receiver is not us, so send via SMTP
                resultingStatus = sendWithSmtp(moc: moc,
                                               senderCdAccount: cdFromAccount,
                                               message: message)
            }
        }

        if !foundAccount {
            // That is a valid case. We are generating keys before saving new account(s) and thus
            // the Engine might try to send something before a CdAccount is persisted.
            Log.shared.info("The Engine asked us to send a message from a non existing account")
        }

        return resultingStatus
    }

    /// Create a core data message from an engine/adapter message.
    /// - Parameters:
    ///   - moc: The managed object context to use
    ///   - message: The pEp sync message, coming from the adapter
    private func baseMessage(moc: NSManagedObjectContext, pEpMessage: PEPMessage) -> CdMessage {
        let cdMsg = CdMessage.from(pEpMessage: pEpMessage, context: moc)
        cdMsg.sent = Date()
        cdMsg.uuid = UUID().uuidString
        return cdMsg
    }

    /// Append a pEp sync message to the given accounts.
    /// - Parameters:
    ///   - moc: The managed object context to use
    ///   - receivingAccounts: The accounts that receive the pEp sync message
    ///   - message: The pEp sync message, coming from the adapter
    private func sendWithAppend(moc: NSManagedObjectContext,
                                receivingAccounts: [CdAccount],
                                pEpMessage: PEPMessage) -> PEPStatus {
        for receiverAccount in receivingAccounts {
            let appendFolder: CdFolder?
            if  usePEPFolderProvider.usePepFolder,
                let pEpFolder = CdFolder.pEpSyncFolder(in: moc, cdAccount: receiverAccount) {
                appendFolder = pEpFolder
            } else {
                // No pEp folder exists or the user disabled using it we append to INBOX.
                appendFolder = CdFolder.by(folderType: .inbox, account: receiverAccount, context: moc)
            }
            // Make sure we have a folder to append to.
            guard let targetFolder = appendFolder else {
                Log.shared.errorAndCrash("Neither sync folder nor inbox found for %@",
                                         receiverAccount.identity?.address ?? "nil address")
                return .unknownError
            }

            // Create a new message that will be appended later by an IMAP service.
            let cdMsg = baseMessage(moc: moc, pEpMessage: pEpMessage)
            cdMsg.parent = targetFolder
            cdMsg.uid = Int32(CdMessage.uidNeedsAppend)

            moc.saveAndLogErrors()
            Log.shared.info("KeySync PEPSendMessageDelegate saved message for appending: %@", cdMsg)
        }

        return .OK
    }

    /// Like `sendWithAppend`, but uses SMTP.
    /// - Parameters:
    ///   - moc: The managed object context to use
    ///   - senderCdAccount: The account of the sender
    ///   - message: The pEp sync message, coming from the adapter
    private func sendWithSmtp(moc: NSManagedObjectContext,
                              senderCdAccount: CdAccount,
                              message: PEPMessage) -> PEPStatus {
        // We need the outbox
        guard let cdOutFolder = CdFolder.by(folderType: .outbox,
                                            account: senderCdAccount,
                                            context: moc)
        else {
            Log.shared.errorAndCrash("No outbox")
            return .unknownError
        }

        // Put the message into the outbox so it will be sent out later by an SMTP service.
        let cdMsg = baseMessage(moc: moc, pEpMessage: message)
        cdMsg.parent = cdOutFolder

        moc.saveAndLogErrors()
        Log.shared.info("KeySync PEPSendMessageDelegate saved message for sending: %@", cdMsg)

        return .OK
    }
}
