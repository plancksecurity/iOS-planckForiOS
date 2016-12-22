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

    public init(backgrounder: BackgroundTaskProtocol? = nil) {
        self.backgrounder = backgrounder
    }

    open override func main() {
        let context = Record.Context.background
        var ids = [NSMutableDictionary]()

        // Which identities are owned?
        context.performAndWait {
            let pOwnIdentity = NSPredicate(format: "isMySelf = true")
            let p = NSCompoundPredicate(andPredicateWithSubpredicates: [pOwnIdentity])
            guard let cdIds = CdIdentity.all(with: p)
                as? [CdIdentity] else {
                    return
            }
            for id in cdIds {
                ids.append(NSMutableDictionary(dictionary: PEPUtil.pEp(cdIdentity: id)))
            }
        }

        // Invoke mySelf on all identities
        var session: PEPSession? = PEPSession()
        for pEpIdDict in ids {
            let taskID = backgrounder?.beginBackgroundTask(taskName: comp) { session = nil }
            session?.mySelf(pEpIdDict)
            backgrounder?.endBackgroundTask(taskID)
        }
    }
}
