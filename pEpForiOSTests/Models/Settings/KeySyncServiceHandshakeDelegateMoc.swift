//
//  KeySyncServiceHandshakeDelegateMoc.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 19/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

final class KeySyncServiceHandshakeDelegateMoc: KeySyncServiceHandshakeDelegate{
    var presenter: UIViewController?

    func showHandshake(me: PEPIdentity, partner: PEPIdentity) {}

    func cancelHandshake() {}

}
