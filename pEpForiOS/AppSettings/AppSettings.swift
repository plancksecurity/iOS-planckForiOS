//
//  AppSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

/**
 Static facade over a `AppSettingsProtocol`, by default using
 `DefaultAppSettings`.
 - Note: You can override the implementation (e.g., in tests) by setting your own
 `settingsHandler`.
 */
struct AppSettings {
    static public let keyReinitializePepOnNextStartup = "keyReinitializePepOnNextStartup"
    static public let keyUnencryptedSubjectEnabled = "keyUnencryptedSubjectEnabled"
    static public let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static public let keyThreadedViewEnabled = "keyThreadedViewEnabled"
    static public let keyPassiveMode = "keyPassiveMode"
    static public let keykeySyncGlobal = "KeySyncGloabl"

    /**
     The actual implementation of `AppSettingsProtocol` to defer to.
     */
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

    static var keySyncGlobal: Bool {
        get {
            return settingsHandler.keySyncGlobal
        }
        set {
            settingsHandler.keySyncGlobal = newValue
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
}
