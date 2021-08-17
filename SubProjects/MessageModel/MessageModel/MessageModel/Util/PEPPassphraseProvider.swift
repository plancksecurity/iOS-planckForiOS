//
//  PassphraseProvider.swift
//  MessageModel
//
//  Created by Andreas Buff on 08.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

import pEpIOSToolbox

/// Pass to adapter PEPObjCAdapter.setPassphraseProvider(PEPPassphraseProviderProtocol).
/// - see: PEPObjCAdapter.PEPPassphraseProviderProtocol docs for details.
class PEPPassphraseProvider: NSObject {
    weak private var delegate:PassphraseProviderProtocol?

    init(delegate:PassphraseProviderProtocol) {
        self.delegate = delegate
    }
}

// MARK: - PEPPassphraseProviderProtocol

extension PEPPassphraseProvider: PEPPassphraseProviderProtocol {

    func passphraseRequired(_ completion: @escaping PEPPassphraseProviderCallback) {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("No delegate")
            completion(nil)
            return
        }
        delegate.showEnterPassphrase(triggeredWhilePEPSync: false,
                                     completion: completion)
    }

    func wrongPassphrase(_ completion: @escaping PEPPassphraseProviderCallback) {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("No delegate")
            completion(nil)
            return
        }
        delegate.showWrongPassphrase(completion: completion)
    }

    func passphraseTooLong(_ completion: @escaping PEPPassphraseProviderCallback) {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("No delegate")
            completion(nil)
            return
        }
        delegate.showPassphraseTooLong(completion: completion)
    }
}
