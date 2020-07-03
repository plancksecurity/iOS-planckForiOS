//
//  KeySyncServiceHandshakeHandlerMoc.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 19/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PEPObjCAdapterFramework

class KeySyncServiceHandshakeHandlerMoc: KeySyncServiceHandshakeHandlerProtocol {
    func showHandshake(me: PEPIdentity,
                       partner: PEPIdentity,
                       isNewGroup: Bool,
                       completion: ((PEPSyncHandshakeResult) -> ())?) {}

    func showError(error: Error?, completion: ((KeySyncErrorResponse) -> ())?) {}

    var presenter: UIViewController?

    func showCurrentlyGroupingDevices() {}

    func cancelHandshake() {}

    func showPassphraseRequired(completion: ((Success)->Void)? = nil) {}

    func showSuccessfullyGrouped() {}
}
