//
//  AppSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AppSettings {

    // MARK: - Public API

    public init() {
        registerDefaults()
        setup()
    }

    public var shouldReinitializePepOnNextStartup: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
        set {
            UserDefaults.standard.set(newValue,
                                      forKey: AppSettings.keyReinitializePepOnNextStartup)
        }
    }

    public var unencryptedSubjectEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyUnencryptedSubjectEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyUnencryptedSubjectEnabled)
            PEPObjCAdapter.setUnEncryptedSubjectEnabled(newValue)
        }

    }

    public var threadedViewEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyThreadedViewEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyThreadedViewEnabled)
        }
    }

    public var passiveMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.keyPassiveMode)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyPassiveMode)
            PEPObjCAdapter.setPassiveModeEnabled(newValue)
        }
    }

    /// Address of the default account
    public var defaultAccount: String? {
        get {
            assureDefaultAccountIsSetAndExists()
            return UserDefaults.standard.string(forKey: AppSettings.keyDefaultAccountAddress)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyDefaultAccountAddress)
        }
    }

    // MARK: Static

    public static var shouldReinitializePepOnNextStartup: Bool {
        get {
            return appSettings.shouldReinitializePepOnNextStartup
        }
        set {
            appSettings.shouldReinitializePepOnNextStartup = newValue
        }
    }

    public static var unencryptedSubjectEnabled: Bool {
        get {
            return appSettings.unencryptedSubjectEnabled
        }
        set {
            appSettings.unencryptedSubjectEnabled = newValue
        }
    }

    public static var threadedViewEnabled: Bool {
        get {
            return appSettings.threadedViewEnabled
        }
        set {
            appSettings.threadedViewEnabled = newValue
        }
    }

    public static var passiveMode: Bool {
        get {
            return appSettings.passiveMode
        }
        set {
            appSettings.passiveMode = newValue
        }
    }

    /// Address of the default account
    public static var defaultAccount: String? {
        get {
            return appSettings.defaultAccount
        }
        set {
            appSettings.defaultAccount = newValue
        }
    }

    // MARK: - Private

    static private let keyReinitializePepOnNextStartup = "keyReinitializePepOnNextStartup"
    static private let keyUnencryptedSubjectEnabled = "keyUnencryptedSubjectEnabled"
    static private let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static private let keyThreadedViewEnabled = "keyThreadedViewEnabled"
    static private let keyPassiveMode = "keyPassiveMode"

    // MARK: DEFAULT ACCOUNT

    private func assureDefaultAccountIsSetAndExists() {
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

    // MARK: SETUP

    private func setup() {
        PEPObjCAdapter.setUnEncryptedSubjectEnabled(unencryptedSubjectEnabled)
        PEPObjCAdapter.setPassiveModeEnabled(passiveMode)
    }

    private func registerDefaults() {
        var defaults = [String: Any]()
        defaults[AppSettings.keyReinitializePepOnNextStartup] = false
        defaults[AppSettings.keyUnencryptedSubjectEnabled] = true
        defaults[AppSettings.keyThreadedViewEnabled] = true
        defaults[AppSettings.keyPassiveMode] = false

        UserDefaults.standard.register(defaults: defaults)
    }

    // MARK: Enable

    static private var appSettings = AppSettings()
}
