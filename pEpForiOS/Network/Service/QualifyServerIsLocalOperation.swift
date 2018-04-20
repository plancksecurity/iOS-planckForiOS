//
//  QualifyServerIsLocalOperation.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Qualifies the given server name re trusted or untrusted, depending on
 whether it is located network-local or not.
 */
class QualifyServerIsLocalOperation: ConcurrentBaseOperation {
    /**
     The server name to be probed for "localness".
     */
    public let serverName: String

    /**
     Flag indicating whether the server is local, or not.
     - Note: The value is only valid after running the operation.
     */
    public var isLocal = false

    init(parentName: String = #function,
         errorContainer: ServiceErrorProtocol = ErrorContainer(),
         serverName: String) {
        self.serverName = serverName
    }
}
