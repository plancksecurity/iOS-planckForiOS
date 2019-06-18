//
//  DefaultAppSettings.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PEPObjCAdapterFramework

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
