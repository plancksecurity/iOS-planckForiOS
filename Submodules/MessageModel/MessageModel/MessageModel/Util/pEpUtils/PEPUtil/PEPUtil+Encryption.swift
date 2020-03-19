//
//  PEPUtil+Encryption.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

/// Encryption related pEp utils collection

import PEPObjCAdapterFramework

extension  PEPUtils {

    static func encrypt(pEpMessage: PEPMessage,
                        encryptionFormat: PEPEncFormat = .PEP,
                        forSelf: PEPIdentity? = nil,
                        extraKeys: [String]? = nil,
                        session: PEPSession = PEPSession()) throws -> PEPMessage {
        var status = PEPStatus.unknownError
        if let ident = forSelf {
            let encryptedMessage = try session.encryptMessage(pEpMessage,
                                                              forSelf: ident,
                                                              extraKeys: extraKeys,
                                                              status: &status)
            return encryptedMessage
        } else {
            let encryptedMessage = try session.encryptMessage(pEpMessage,
                                                        extraKeys: extraKeys,
                                                        encFormat: encryptionFormat,
                                                        status: &status)
            return encryptedMessage
        }
    }
}
