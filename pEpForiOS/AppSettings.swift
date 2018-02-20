//
//  AppSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class AppSettings {
    static private let keyReinitializePepOnNextStartup = "reinitializePepOnNextStartup"
    static private let keyUnecryptedSubjectEnabled = "unecryptedSubjectEnabled"
    static private let keyAppendTrashMails = "keyAppendTrashMails"

    var shouldReinitializePepOnNextStartup: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
    }

    var shouldSyncImapTrashWithServer: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyAppendTrashMails)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyAppendTrashMails)
        }
    }

    var unecryptedSubjectEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyUnecryptedSubjectEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyUnecryptedSubjectEnabled)
        }
    }


    init() {
        registerDefaults()
    }

    private func registerDefaults() {
        var defaults = [String: Any]()
        defaults[AppSettings.keyReinitializePepOnNextStartup] = false
        defaults[AppSettings.keyAppendTrashMails] = false
        defaults[AppSettings.keyUnecryptedSubjectEnabled] = true
        UserDefaults.standard.register(defaults: defaults)
    }
}
