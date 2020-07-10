//
//  UserInputProvider+PassphraseProviderProtocol.swift
//  pEp
//
//  Created by Andreas Buff on 08.07.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - UserInputProvider+PassphraseProviderProtocol

extension UserInputProvider: PassphraseProviderProtocol {

    func showEnterPassphrase(triggeredWhilePEPSync: Bool = false,
                             completion: @escaping (String?)->Void) {
        if triggeredWhilePEPSync {
            UIUtils.showPassphraseRequiredForPEPSyncAlert(completion: completion)
        } else {
            UIUtils.showPassphraseRequiredAlert(completion: completion)
        }
    }

    func showWrongPassphrase(completion: @escaping (String?)->Void) {
        UIUtils.showWrongPassphraseAlert(completion: completion)
    }

    func showPassphraseTooLong(completion: @escaping (String?)->Void) {
        UIUtils.showWrongPassphraseAlert(completion: completion)
    }
}
