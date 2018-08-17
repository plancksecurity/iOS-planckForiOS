//
//  AppSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

struct AppSettings {
    // Assures init is called once.
    static private var appSettings = AppSettings()

    static private let keyReinitializePepOnNextStartup = "keyReinitializePepOnNextStartup"
    static private let keyUnencryptedSubjectEnabled = "keyUnencryptedSubjectEnabled"
    static private let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static private let keyThreadedViewEnabled = "keyThreadedViewEnabled"
    static private let keyPassiveMode = "keyPassiveMode"
    static private let keyManuallyTrustedServers = "keyManuallyTrustedServers"

    // MARK: - API

    static func setupObjcAdapter() {
        PEPObjCAdapter.setUnEncryptedSubjectEnabled(AppSettings.unencryptedSubjectEnabled)
        PEPObjCAdapter.setPassiveModeEnabled(AppSettings.passiveMode)
    }

    static var shouldReinitializePepOnNextStartup: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
        set {
            UserDefaults.standard.set(newValue,
                                      forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
    }

    static var unencryptedSubjectEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyUnencryptedSubjectEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyUnencryptedSubjectEnabled)
            PEPObjCAdapter.setUnEncryptedSubjectEnabled(newValue)
        }
    }

    static var threadedViewEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyThreadedViewEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyThreadedViewEnabled)
        }
    }

    static var passiveMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyPassiveMode)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyPassiveMode)
            PEPObjCAdapter.setPassiveModeEnabled(newValue)
        }
    }

    /// Address of the default account
    static var defaultAccount: String? {
        get {
            assureDefaultAccountIsSetAndExists()
            return UserDefaults.standard.string(forKey: AppSettings.keyDefaultAccountAddress)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyDefaultAccountAddress)
        }
    }

    /// Addresses of all accounts the user explicitly trusted
    static var manuallyTrustedServers: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: keyManuallyTrustedServers) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyManuallyTrustedServers)
        }
    }

    // MARK: SETUP

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        var defaults = [String: Any]()
        defaults[AppSettings.keyReinitializePepOnNextStartup] = false
        defaults[AppSettings.keyUnencryptedSubjectEnabled] = true
        defaults[AppSettings.keyThreadedViewEnabled] = true
        defaults[AppSettings.keyPassiveMode] = false

        UserDefaults.standard.register(defaults: defaults)
    }

    // MARK: - Other

    static private func assureDefaultAccountIsSetAndExists() {
        if UserDefaults.standard.string(forKey: AppSettings.keyDefaultAccountAddress) == nil {
            // Default account is not set. Take the first MessageModel provides as a starting point
            let initialDefault = Account.all().first?.user.address
            UserDefaults.standard.set(initialDefault, forKey: AppSettings.keyDefaultAccountAddress)
        }
        // Assure the default account still exists. The user might have deleted it.
        guard
            let currentDefault = UserDefaults.standard.string(
                forKey: AppSettings.keyDefaultAccountAddress),
            let _ = Account.by(address: currentDefault)
            else {
                defaultAccount = nil
                return
        }
    }
}
