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

    public static func gatherConnectInfos(accounts: [Account]) -> [AccountConnectInfo] {
        var connectInfos = [AccountConnectInfo]()
        for acc in accounts {
            let smtpCI = acc.smtpConnectInfo
            let imapCI = acc.imapConnectInfo
            if (smtpCI != nil || imapCI != nil) {
                let accObjID: NSManagedObjectID
                if let objId = smtpCI?.accountObjectID {
                    accObjID = objId
                } else if let objId = imapCI?.accountObjectID {
                    accObjID = objId
                } else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No objId")
                    accObjID = NSManagedObjectID() // Use nonsense
                }
                connectInfos.append(AccountConnectInfo(needsVerification: acc.needsVerification,
                                                       accountID: accObjID,
                                                       imapConnectInfo: imapCI,
                                                       smtpConnectInfo: smtpCI))
            }
        }
        return connectInfos
    }
}
