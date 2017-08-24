//
//  PEPSessionCreator.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

/// Always use this to create a PEPSession to avoid concurrent calls to PEPSession.init (and thus crahses).
final class PEPSessionCreator {
    static let shared = PEPSessionCreator()

    private init() {}

    final func newSession() -> PEPSession {
        objc_sync_enter(self)
        let session = PEPSession()
        objc_sync_exit(self)
        return session
    }
}
