//
//  KeySyncHandshakeService.swift
//  pEp
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol KeySyncHandshakeServiceDelegate: class {
    func showHandshakeView(for me: Identity, partner: Identity) -> Int// Result ???
}

class KeySyncHandshakeService {
    weak var delegate: KeySyncHandshakeServiceDelegate?

    init(delegate: KeySyncHandshakeServiceDelegate? = nil) {
        self.delegate = delegate
    }



}
