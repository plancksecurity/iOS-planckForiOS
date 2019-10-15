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
    // Keys
    static private let keyReinitializePepOnNextStartup = "keyReinitializePepOnNextStartup"
    static private let keyKeySyncEnabled = "keyStartpEpSync"
    static private let keyUnencryptedSubjectEnabled = "keyUnencryptedSubjectEnabled"
    static private let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static private let keyThreadedViewEnabled = "keyThreadedViewEnabled"
    static private let keyPassiveMode = "keyPassiveMode"
    static private let keyLastKnowDeviceGroupStateRawValue = "keyLastKnowDeviceGroupStateRawValue"
    static private let keyExtraKeysEditable = "keyExtraKeysEditable"
    static private let keyShouldShowTutorialWizard = "keyShouldShowTutorialWizard"
    static private let keyUserHasBeenAskedForContactAccessPermissions = "keyUserHasBeenAskedForContactAccessPermissions"

    static private let appGroupId = "group.security.pep.pep4ios"
    static private var userDefaults: UserDefaults = {
        guard let appGroupDefaults = UserDefaults.init(suiteName: appGroupId) else {
            Log.shared.errorAndCrash("Could not find app group defaults")
            return UserDefaults.standard
        }
        return appGroupDefaults
    }()

    init() {
        setup()
    }

    public var shouldReinitializePepOnNextStartup: Bool {
        get {
            return DefaultAppSettings.userDefaults.bool(forKey: DefaultAppSettings.keyReinitializePepOnNextStartup)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue,
                                      forKey: DefaultAppSettings.keyReinitializePepOnNextStartup)
        }
    }

    public var keySyncEnabled: Bool {
        get {
            return DefaultAppSettings.userDefaults.bool(forKey: DefaultAppSettings.keyKeySyncEnabled)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue,
                                      forKey: DefaultAppSettings.keyKeySyncEnabled)
        }
    }

    public var extraKeysEditable: Bool {
        get {
            return DefaultAppSettings.userDefaults.bool(forKey: DefaultAppSettings.keyExtraKeysEditable)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue, forKey: DefaultAppSettings.keyExtraKeysEditable)
        }
    }
    
    public var unencryptedSubjectEnabled: Bool {
        get {
            return DefaultAppSettings.userDefaults.bool(forKey: DefaultAppSettings.keyUnencryptedSubjectEnabled)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue,
                                      forKey: DefaultAppSettings.keyUnencryptedSubjectEnabled)
            PEPObjCAdapter.setUnEncryptedSubjectEnabled(newValue)
        }
    }

    public var threadedViewEnabled: Bool {
        get {
            return false
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue, forKey: DefaultAppSettings.keyThreadedViewEnabled)
        }
    }

    public var passiveMode: Bool {
        get {
            return DefaultAppSettings.userDefaults.bool(forKey: DefaultAppSettings.keyPassiveMode)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue, forKey: DefaultAppSettings.keyPassiveMode)
            PEPObjCAdapter.setPassiveModeEnabled(newValue)
        }
    }

    public var shouldShowTutorialWizard: Bool {
        get {
            return DefaultAppSettings.userDefaults.bool(forKey: DefaultAppSettings.keyShouldShowTutorialWizard)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue,
                                      forKey: DefaultAppSettings.keyShouldShowTutorialWizard)
        }
    }

    public var userHasBeenAskedForContactAccessPermissions: Bool {
        get {
            return DefaultAppSettings.userDefaults.bool(forKey: DefaultAppSettings.keyUserHasBeenAskedForContactAccessPermissions)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue,
                                      forKey: DefaultAppSettings.keyUserHasBeenAskedForContactAccessPermissions)
        }
    }

    /// Address of the default account
    public var defaultAccount: String? {
        get {
            assureDefaultAccountIsSetAndExists()
            return DefaultAppSettings.userDefaults.string(forKey: DefaultAppSettings.keyDefaultAccountAddress)
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue,
                                      forKey: DefaultAppSettings.keyDefaultAccountAddress)
        }
    }

    public var lastKnownDeviceGroupState: DeviceGroupState {
        get {
            let rawValue = DefaultAppSettings.userDefaults.integer(forKey: DefaultAppSettings.keyLastKnowDeviceGroupStateRawValue)
            return DeviceGroupState(rawValue: rawValue) ?? DeviceGroupState.sole
        }
        set {
            DefaultAppSettings.userDefaults.set(newValue.rawValue,
                                      forKey: DefaultAppSettings.keyLastKnowDeviceGroupStateRawValue)
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
        defaults[DefaultAppSettings.keyReinitializePepOnNextStartup] = false //BUFF: ???: obsolete?
        defaults[DefaultAppSettings.keyKeySyncEnabled] = true
        defaults[DefaultAppSettings.keyUnencryptedSubjectEnabled] = false
        defaults[DefaultAppSettings.keyThreadedViewEnabled] = true
        defaults[DefaultAppSettings.keyPassiveMode] = false
        defaults[DefaultAppSettings.keyLastKnowDeviceGroupStateRawValue] = DeviceGroupState.sole.rawValue
        defaults[DefaultAppSettings.keyExtraKeysEditable] = false
        defaults[DefaultAppSettings.keyShouldShowTutorialWizard] = true
        defaults[DefaultAppSettings.keyUserHasBeenAskedForContactAccessPermissions] = false

        DefaultAppSettings.userDefaults.register(defaults: defaults)
    }

    // MARK: - Other

    private func assureDefaultAccountIsSetAndExists() {
        if DefaultAppSettings.userDefaults.string(forKey: DefaultAppSettings.keyDefaultAccountAddress) == nil {
            // Default account is not set. Take the first MessageModel provides as a starting point
            let initialDefault = Account.all().first?.user.address
            DefaultAppSettings.userDefaults.set(initialDefault, forKey: DefaultAppSettings.keyDefaultAccountAddress)
        }
        // Assure the default account still exists. The user might have deleted it.
        guard
            let currentDefault = DefaultAppSettings.userDefaults.string(
                forKey: DefaultAppSettings.keyDefaultAccountAddress),
            let _ = Account.by(address: currentDefault)
            else {
                defaultAccount = nil
                return
        }
    }
}
