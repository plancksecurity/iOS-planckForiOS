//
//  MySelfOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/**
 Triggers myself on all identities who are own identities.
 */
open class MySelfOperation: BaseOperation {
    let backgrounder: BackgroundTaskProtocol?

    public init(backgroundTaskExe: BackgroundTaskProtocol? = nil) {
        self.backgrounder = backgroundTaskExe
    }

    open override func main() {
        let context = Record.Context.background
        var ids = [NSManagedObjectID: NSMutableDictionary]()

        // Which identities are owned?
        context.performAndWait {
            let pOwnIdentity = NSPredicate(format: "isMySelf = true")
            let pHasNoFpr = NSPredicate(format: "fingerPrint = nil or fingerPrint = \"\"")
            let p = NSCompoundPredicate(andPredicateWithSubpredicates: [pOwnIdentity, pHasNoFpr])
            guard let cdIds = CdIdentity.all(with: p)
                as? [CdIdentity] else {
                    return
            }
            for id in cdIds {
                ids[id.objectID] = NSMutableDictionary(dictionary: PEPUtil.pEp(cdIdentity: id))
            }
        }

        // Invoke mySelf on all identities
        var session: PEPSession? = PEPSession()
        for pEpIdDict in ids.values {
            let taskID = backgrounder?.beginBackgroundTask() { session = nil }
            session?.mySelf(pEpIdDict)
            backgrounder?.endBackgroundTask(taskID)
        }

        context.performAndWait {
            for (cdId, idDict) in ids {
                guard let cdIdentity = context.object(with: cdId) as? CdIdentity else {
                    continue
                }
                if let fpr = idDict[kPepFingerprint] as? String {
                    cdIdentity.fingerPrint = fpr
                }
            }
            Record.saveAndWait(context: context)
        }
    }
}
