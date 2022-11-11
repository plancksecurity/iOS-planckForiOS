//
//  AppSettingsRemover.swift
//  pEp
//
//  Created by Martín Brude on 10/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

class AppSettingsRemover {

    // The keys that has been removed.
    private var removedKeys: [String] = []

    /// Indicates if the given key has been removed from user defaults.
    public func hasBeenRemoved(key: String) -> Bool {
        return removedKeys.contains(key)
    }

    func removeFromUserDefaults(key: String) {
        // Get the MDM dictionary, remove the key, prevent the updates through the app, update the dictionary.
        if var mdm = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) {
            mdm.removeValue(forKey: key)
            removedKeys.append(key)
            UserDefaults.standard.set(mdm, forKey: MDMPredeployed.keyMDM)
        }
    }
}
