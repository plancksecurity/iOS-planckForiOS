//
//  CdServer+Extensions.swift
//  MessageModel
//
//  Created by buff on 07.08.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

extension CdServer {
    var serverType: Server.ServerType {
        get {
            guard let type = Server.ServerType(rawValue: self.serverTypeRawValue) else {
                Log.shared.errorAndCrash("No server type?!")
                //this does not make sense as a default value, but as serverTypeRawValue is non-optional, this guard should never fail
                return Server.ServerType.imap
            }
            return type
        }
        set {
            self.serverTypeRawValue = newValue.rawValue
        }
    }

    var transport: Server.Transport {
        get {
            guard let type = Server.Transport(rawValue: self.transportRawValue) else {
                Log.shared.errorAndCrash("No server transport?!")
                return Server.Transport.plain
            }
            return type
        }
        set {
            self.transportRawValue = newValue.rawValue
        }
    }
}
