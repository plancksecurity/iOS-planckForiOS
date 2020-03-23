//
//  CdAccount+ProviderSpecificTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 18.03.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel

class CdAccount_ProviderSpecificTest: XCTestCase {
    func testAccountType() {
        // input -> expected output
        let accountTypes = [VerifiableAccount.AccountType.gmail:VerifiableAccount.AccountType.gmail,
                            .o365:.o365,
                            .outlook:.o365,
                            .icloud:.icloud]

        let moc = Stack.shared.newPrivateConcurrentContext

        moc.performAndWait {
            for (accTypeIn, accTypeOut) in accountTypes {
                let cdAccount = createFakeAccount(moc: moc,
                                                  accountType: accTypeIn)
                XCTAssertEqual(cdAccount.accountType, accTypeOut)
            }
        }
    }

    // MARK - Helpers

    private func createFakeAccount(moc: NSManagedObjectContext,
                                   accountType: VerifiableAccount.AccountType) -> CdAccount {
        let verifier = VerifiableAccount.verifiableAccount(for: accountType)

        let cdIdentity = CdIdentity(context: moc)
        cdIdentity.userName = "userName_\(accountType)"
        cdIdentity.address = "address_\(accountType)"

        let cdAccount = CdAccount(context: moc)
        cdAccount.identity = cdIdentity

        let cdImapServer = CdServer(context: moc)
        cdImapServer.address = verifier.serverIMAP
        cdImapServer.port = Int16(verifier.portIMAP)
        cdImapServer.serverType = .imap
        cdImapServer.transport = .tls

        let cdSmtpServer = CdServer(context: moc)
        cdSmtpServer.address = verifier.serverSMTP
        cdSmtpServer.port = Int16(verifier.portSMTP)
        cdSmtpServer.serverType = .smtp
        cdSmtpServer.transport = .tls

        let cdCreds = CdServerCredentials(context: moc)
        cdCreds.key = "key_\(accountType)"
        cdCreds.loginName = "loginName_\(accountType)"

        cdImapServer.credentials = cdCreds
        cdSmtpServer.credentials = cdCreds

        cdAccount.addToServers(cdImapServer)
        cdAccount.addToServers(cdSmtpServer)

        moc.saveAndLogErrors()

        return cdAccount
    }
}
