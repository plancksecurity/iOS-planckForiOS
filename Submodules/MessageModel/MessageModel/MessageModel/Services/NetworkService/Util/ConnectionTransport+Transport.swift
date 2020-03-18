//
//  ConnectionTransport+Transport.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 15.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework

public extension ConnectionTransport {
    init(transport: Server.Transport) {
        switch transport {
        case .plain:
            self = .plain
        case .startTls:
            self = .startTLS
        case .tls:
            self = .TLS
        }
    }
}
