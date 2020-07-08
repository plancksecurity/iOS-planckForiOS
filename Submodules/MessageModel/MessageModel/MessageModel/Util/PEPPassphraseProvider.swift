//
//  PassphraseProvider.swift
//  MessageModel
//
//  Created by Andreas Buff on 08.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

//BUFF: DUMMY. Delete and use the real adapter protocol after existance
protocol PEPPassphraseProviderProtocol {
    func passphraseRequired(completion:  @escaping (String?)->Void)
    func wrongPassphrase(completion:  @escaping (String?)->Void)
    func passphraseTooLong(completion:  @escaping (String?)->Void)
}

//BUFF: ToDo: pass provider instance to Adapter
class PEPPassphraseProvider {
    weak private var delegate:PassphraseProviderProtocol?

    init(delegate:PassphraseProviderProtocol) {
        self.delegate = delegate
    }
}

// MARK: - PEPPassphraseProviderProtocol

extension PEPPassphraseProvider: PEPPassphraseProviderProtocol {

    func passphraseRequired(completion: @escaping (String?) -> Void) {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("No delegate")
            completion(nil)
            return
        }
        delegate.showEnterPassphrase(completion: completion)
    }

    func wrongPassphrase(completion:  @escaping (String?) -> Void) {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("No delegate")
            completion(nil)
            return
        }
        delegate.showWrongPassphrase(completion: completion)
    }

    func passphraseTooLong(completion: @escaping  (String?) -> Void) {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("No delegate")
            completion(nil)
            return
        }
        delegate.showPassphraseTooLong(completion: completion)
    }
}
