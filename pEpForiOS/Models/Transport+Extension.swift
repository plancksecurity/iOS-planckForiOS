//
//  Transport+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension Server.Transport {
    public var connectionTransport: ConnectionTransport {
        switch self {
        case .plain: return ConnectionTransport.plain
        case .tls: return ConnectionTransport.TLS
        case .startTls: return ConnectionTransport.startTLS
        }
    }
}
