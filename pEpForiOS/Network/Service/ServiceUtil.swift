//
//  ServiceUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

open class ServiceUtil {
    public static func gatherConnectInfos(context: NSManagedObjectContext,
                                          accounts: [CdAccount]) -> [AccountConnectInfo] {
        var connectInfos = [AccountConnectInfo]()
        context.performAndWait {
            for acc in accounts {
                let smtpCI = acc.smtpConnectInfo
                let imapCI = acc.imapConnectInfo
                if (smtpCI != nil || imapCI != nil) {
                    connectInfos.append(AccountConnectInfo(
                        needsVerification: acc.needsVerification,
                        accountID: acc.objectID, imapConnectInfo: imapCI, smtpConnectInfo: smtpCI))
                }
            }
        }
        return connectInfos
    }

    public static func cachedImapSync(imapConnectionDataCache: [EmailConnectInfo: ImapSyncData],
                                      connectInfo: EmailConnectInfo) -> ImapSyncData {
        var imapConnectionDataCache = imapConnectionDataCache
        if let syncData = imapConnectionDataCache[connectInfo] {
            return syncData
        }
        let imapSyncData = ImapSyncData(connectInfo: connectInfo)
        imapConnectionDataCache[connectInfo] = imapSyncData
        return imapSyncData
    }
}
