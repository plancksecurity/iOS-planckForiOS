//
//  SharedObjects.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

/**
 Used for building a line of operations for synching an account.
 */
public struct AccountConnectInfo {
    public let accountID: NSManagedObjectID
    public let imapConnectInfo: EmailConnectInfo?
    public let smtpConnectInfo: EmailConnectInfo?
}

/**
 Used for parameters/state shared between IMAP related operations.
 */
open class ImapSyncData {
    public var sync: ImapSync?
}
