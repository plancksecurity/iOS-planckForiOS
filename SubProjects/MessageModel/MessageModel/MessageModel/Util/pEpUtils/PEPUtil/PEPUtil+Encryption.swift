//
//  PEPUtil+Encryption.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

/// Encryption related pEp utils collection

import PEPObjCAdapterTypes_iOS
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

extension  PEPUtils {
    
    static func encrypt(pEpMessage: PEPMessage,
                        encryptionFormat: PEPEncFormat = .PEP,
                        forSelf: PEPIdentity? = nil,
                        extraKeys: [String]? = nil,
                        errorCallback: @escaping (_ error:Error) -> Void,
                        successCallback: @escaping (_ srcMsg:PEPMessage, _ destMsg:PEPMessage) -> Void) {
        if let ident = forSelf {
            PEPSession().encryptMessage(pEpMessage,
                                        forSelf: ident,
                                        extraKeys: extraKeys,
                                        errorCallback: errorCallback,
                                        successCallback: successCallback)
        } else {
            PEPSession().encryptMessage(pEpMessage,
                                        extraKeys: extraKeys,
                                        encFormat: encryptionFormat,
                                        errorCallback: errorCallback,
                                        successCallback: successCallback)
            
        }
    }
}
