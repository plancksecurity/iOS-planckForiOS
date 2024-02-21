//
//  CdServer+PredicateFactory.swift
//  MessageModel
//
//  Created by Andreas Buff on 17.08.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdServer {

    struct PredicateFactory {

        static func isAllowedToManuallyTrust() -> NSPredicate {
            let pImap = isImap()
            return
                NSCompoundPredicate(andPredicateWithSubpredicates: [pImap])
        }

        static func isImap() -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                                         CdServer.AttributeName.serverTypeRawValue,
                                         Server.ServerType.imap.rawValue)
        }
    }
}
