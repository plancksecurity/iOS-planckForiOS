//
//  CdServerCredentials+KeyChain.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

// MARK: - Password & KeyChain Access

extension CdServerCredentials {

    var password: String? {
        get {
            guard let theKey = key else {
                return nil
            }
            return KeyChain.serverPassword(forKey: theKey)
        }
        set {
            key = key ?? UUID().uuidString
            guard let safeKey = key else {
                Log.shared.errorAndCrash("We just set a key but have none?")
                return
            }
            KeyChain.updateCreateOrDelete(password: newValue, forKey: safeKey)
        }
    }

    /// Is not meant to be public, but must be, since the xcode-generated base class is
    public override func validateForDelete() throws {
        guard let key = key else {
            // No key is set yet, nothing to do.
            return
        }
        CdServerCredentials.deletePassword(forKey: key)
        try super.validateForDelete()
    }

    /// Fixes the case where after a restore from a backup, key chain passwords are lost,
    /// as seen in IOS-2932/PEMA-134.
    public func fixLostPassword() {
        guard let theKey = key else {
            return
        }

        let password = KeyChain.serverPassword(forKey: theKey)

        if password == nil {
            // In case that is the real password, then we just guessed it
            // successfully by brute-force, even better.
            // But that is unlikely, and a wrong password is better than nil
            // for the UI, and not worse for networking.
            KeyChain.updateCreateOrDelete(password: "password", forKey: theKey)
        }
    }

    static func add(password: String?, forKey: String) {
        KeyChain.updateCreateOrDelete(password: password, forKey: forKey)
    }

    static func deletePassword(forKey key: String) {
        KeyChain.updateCreateOrDelete(password: nil, forKey: key)
    }
}
