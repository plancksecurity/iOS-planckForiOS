//
//  DecryptionUtil.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel

class DecryptionUtil {

    public static func createLocalAccount(ownUserName: String,
                                          ownUserID: String,
                                          ownEmailAddress: String,
                                          context: NSManagedObjectContext) -> CdAccount {
        let cdOwnAccount = SecretTestData().createWorkingCdAccount(number: 0, context: context)
        cdOwnAccount.identity?.userName = ownUserName
        cdOwnAccount.identity?.userID = ownUserID
        cdOwnAccount.identity?.address = ownEmailAddress

        let cdInbox = CdFolder(context: context)
        cdInbox.name = ImapConnection.defaultInboxName
        cdInbox.account = cdOwnAccount
        context.saveAndLogErrors()

        return cdOwnAccount
    }
}
