//
//  AppSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AppSettings {
    static private let keyReinitializePepOnNextStartup = "reinitializePepOnNextStartup"
    static private let keyUnecryptedSubjectEnabled = "unecryptedSubjectEnabled"
    static private let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static private let keyThreadedViewEnabled = "threadedViewEnabled"

    init() {
        registerDefaults()
        setup()
    }

    var shouldReinitializePepOnNextStartup: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
    }

    var unecryptedSubjectEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyUnecryptedSubjectEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyUnecryptedSubjectEnabled)
            PEPObjCAdapter.setUnEncryptedSubjectEnabled(newValue)
        }

    }

    var threadedViewEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyThreadedViewEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyThreadedViewEnabled)
        }
    }

    // MARK: - DEFAULT ACCOUNT

    /// Address of the default account
    var defaultAccount: String? {
        get {
            assureDefaultAccountIsSetAndExists()
            return UserDefaults.standard.string(forKey: AppSettings.keyDefaultAccountAddress)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyDefaultAccountAddress)
        }
    }

    private func assureDefaultAccountIsSetAndExists() {
        if UserDefaults.standard.string(forKey: AppSettings.keyDefaultAccountAddress) == nil {
            // Default account is not set. Take the first MessageModel provides as a starting point
            let initialDefault = Account.all().first?.user.address
            UserDefaults.standard.set(initialDefault, forKey: AppSettings.keyDefaultAccountAddress)
        }
        // Assure the default account still exists. The user might have deleted it.
        guard
            let currentDefault = UserDefaults.standard.string(forKey: AppSettings.keyDefaultAccountAddress),
            let _ = Account.by(address: currentDefault)
            else {
                defaultAccount = nil
                return
        }
    }

    // MARK: - SETUP

    private func setup() {
        PEPObjCAdapter.setUnEncryptedSubjectEnabled(unecryptedSubjectEnabled)
    }

    private func registerDefaults() {
        var defaults = [String: Any]()
        defaults[AppSettings.keyReinitializePepOnNextStartup] = false
        defaults[AppSettings.keyUnecryptedSubjectEnabled] = true
        defaults[AppSettings.keyThreadedViewEnabled] = true

        UserDefaults.standard.register(defaults: defaults)
    }
}
