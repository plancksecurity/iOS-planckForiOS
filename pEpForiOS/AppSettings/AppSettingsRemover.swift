//
//  AppSettingsRemover.swift
//  pEp
//
//  Created by Martín Brude on 10/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Helper class to aim removing sensitve data from UserDefaults.
class AppSettingsRemover {

    /// The keys that has been removed.
    private var removedKeys: [String] = []

    /// Indicates if the given key has been removed from user defaults.
    public func hasBeenRemoved(key: String) -> Bool {
        if removedKeys.contains(key) {
            removedKeys = removedKeys.filter { $0 != key }
            return true
        }
        return false
    }

    /// Removes the key from standard UserDefaults (not pEp's instance of UserDefaults)
    public func removeFromUserDefaults(key: String) {
        // Get a copy of the MDM dictionary
        if var mdm = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) {
            // Remove the value for the given key from the copied dictionary
            mdm.removeValue(forKey: key)
            // Prevent the updates through the app by adding the key to the removedKeys array
            removedKeys.append(key)
            // Update the dictionary which will trigger updates trough the app.
            UserDefaults.standard.set(mdm, forKey: MDMPredeployed.keyMDM)
        }
    }
}
