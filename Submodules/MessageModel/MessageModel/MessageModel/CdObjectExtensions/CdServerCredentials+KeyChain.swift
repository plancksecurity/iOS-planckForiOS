//
//  CdServerCredentials+KeyChain.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

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

    public override func validateForDelete() throws {
        guard let key = key else {
            // No key is set yet, nothing to do.
            return
        }
        CdServerCredentials.deletePassword(forKey: key)
        try super.validateForDelete()
    }

    static func add(password: String?, forKey: String) {
        KeyChain.updateCreateOrDelete(password: password, forKey: forKey)
    }

    static func deletePassword(forKey key: String) {
        KeyChain.updateCreateOrDelete(password: nil, forKey: key)
    }
}

