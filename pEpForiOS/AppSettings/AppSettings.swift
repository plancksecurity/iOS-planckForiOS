//
//  AppSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class DefaultAppSettings: AppSettingsProtocol {
    init() {
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
            return false
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

    // MARK: manuallyTrustedServers

    /// Addresses of all accounts the user explicitly trusted
    public var manuallyTrustedServers: [String] {
        get {
            return UserDefaults.standard.stringArray(
                forKey: AppSettings.keyManuallyTrustedServers) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.keyManuallyTrustedServers)
        }
    }

    public func isManuallyTrustedServer(address: String) -> Bool {
        return manuallyTrustedServers.contains(address)
    }

    public func addToManuallyTrustedServers(address: String) {
        var addresses = Set(manuallyTrustedServers)
        addresses.insert(address)
        manuallyTrustedServers = Array(addresses)
    }

    public func removeFromManuallyTrustedServers(address: String) {
        var addresses = Set(manuallyTrustedServers)
        addresses.remove(address)
        manuallyTrustedServers = Array(addresses)
    }

    // MARK: - Setup

    private func setup() {
        registerDefaults()
        setupObjcAdapter()
    }

    private func setupObjcAdapter() {
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

    // MARK: - Other

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
}

struct AppSettings {
    static public let keyReinitializePepOnNextStartup = "keyReinitializePepOnNextStartup"
    static public let keyUnencryptedSubjectEnabled = "keyUnencryptedSubjectEnabled"
    static public let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static public let keyThreadedViewEnabled = "keyThreadedViewEnabled"
    static public let keyPassiveMode = "keyPassiveMode"
    static public let keyManuallyTrustedServers = "keyManuallyTrustedServers"

    static public var settingsHandler: AppSettingsProtocol = DefaultAppSettings()

    // MARK: - API

    static var shouldReinitializePepOnNextStartup: Bool {
        get {
            return settingsHandler.shouldReinitializePepOnNextStartup
        }
        set {
            settingsHandler.shouldReinitializePepOnNextStartup = newValue
        }
    }

    static var unencryptedSubjectEnabled: Bool {
        get {
            return settingsHandler.unencryptedSubjectEnabled
        }
        set {
            settingsHandler.unencryptedSubjectEnabled = newValue
        }
    }

    static var threadedViewEnabled: Bool {
        get {
            return settingsHandler.threadedViewEnabled
        }
        set {
            settingsHandler.threadedViewEnabled = newValue
        }
    }

    static var passiveMode: Bool {
        get {
            return settingsHandler.passiveMode
        }
        set {
            settingsHandler.passiveMode = newValue
        }
    }

    /// Address of the default account
    static var defaultAccount: String? {
        get {
            return settingsHandler.defaultAccount
        }
        set {
            settingsHandler.defaultAccount = newValue
        }
    }

    // MARK: manuallyTrustedServers

    /// Addresses of all accounts the user explicitly trusted
    static var manuallyTrustedServers: [String] {
        get {
            return settingsHandler.manuallyTrustedServers
        }
        set {
            settingsHandler.manuallyTrustedServers = newValue
        }
    }

    static func isManuallyTrustedServer(address: String) -> Bool {
        return manuallyTrustedServers.contains(address)
    }

    static func addToManuallyTrustedServers(address: String) {
        settingsHandler.addToManuallyTrustedServers(address: address)
    }

    static func removeFromManuallyTrustedServers(address: String) {
        settingsHandler.removeFromManuallyTrustedServers(address: address)
    }
}
