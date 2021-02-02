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
            let pNotInLocalNetworkWhenCreated = notAutomaticallyTrusted()
            return
                NSCompoundPredicate(andPredicateWithSubpredicates: [pImap,
                                                                    pNotInLocalNetworkWhenCreated])
        }

        static func isImap() -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                                         CdServer.AttributeName.serverTypeRawValue,
                                         Server.ServerType.imap.rawValue)
        }
        
        static func notAutomaticallyTrusted() -> NSPredicate {
            return NSPredicate(format: "%K = false", CdServer.AttributeName.automaticallyTrusted)
        }
    }
}
