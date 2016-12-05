//
//  MySelfOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/**
 Triggers myself on all identities who are own identities.
 */
open class MySelfOperation: BaseOperation {
    open override func main() {
        let context = Record.Context.default
        var ids = [CdIdentity:NSMutableDictionary]()

        // Which identities are owned?
        context.performAndWait {
            guard let cdIds = CdIdentity.all(with: NSPredicate(format: "isMySelf = true"))
                as? [CdIdentity] else {
                    return
            }
            for id in cdIds {
                ids[id] = NSMutableDictionary(dictionary: PEPUtil.pEp(cdIdentity: id))
            }
        }

        // Invoke mySelf on all identities
        let session = PEPSession()
        for pEpIdDict in ids.values {
            session.mySelf(pEpIdDict)
        }

        context.performAndWait {
            for (cdId, idDict) in ids {
                if let fpr = idDict[kPepFingerprint] as? String {
                    cdId.fingerPrint = fpr
                }
            }
            Record.saveAndWait(context: context)
        }
    }
}
