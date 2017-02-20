//
//  ShortCircuitSendLayer.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/**
 Invoke completion block without errors for all actions.
 */
class ShortCircuitSendLayer: SendLayerProtocol {
    var sendLayerDelegate: SendLayerDelegate? = DefaultSendLayerDelegate()

    func verify(cdAccount: CdAccount) {
        sendLayerDelegate?.didVerify(cdAccount: cdAccount, error: nil)
    }
}
