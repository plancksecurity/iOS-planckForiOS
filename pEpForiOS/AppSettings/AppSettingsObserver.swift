//
//  AppSettingsObserver.swift
//  pEp
//
//  Created by Martín Brude on 7/9/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AppSettingsObserver {

    /// Singleton instance of the observer.
    /// To start observing, you MUST call `start`, only once.
    static public let shared = AppSettingsObserver()

    /// Start observing MDM settings.
    public func start() {
        if let values = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) {
            mdmDictionary = values
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsDidChange),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    // MARK: - Private

    private var mdmDictionary: [String:Any] = [:]

    @objc private func userDefaultsDidChange(notification: NSNotification) {
        // We only care about standard user default settings, and specifically mdm settings
        guard let defaults = notification.object as? UserDefaults,
              defaults == UserDefaults.standard,
              let mdm = defaults.dictionary(forKey: MDMPredeployed.keyMDM) else {
            // Nothing to do
            return
        }

        // Detect changes to the media keys
        if let oldValues = NSDictionary(dictionary: mdmDictionary).value(forKey: AppSettings.keyMediaKeys) as? [[String:String]] {
            let newValues = AppSettings.shared.mdmMediaKeys
            if oldValues != newValues {
                MediaKeysUtil().configure(mediaKeyDictionaries: newValues)
            }
        }

        // Detect if there is a change re: Echo Protocol
        if let oldValue = NSDictionary(dictionary: mdmDictionary)
            .value(forKey: AppSettings.keyEchoProtocolEnabled) as? Bool {
            let newValue = AppSettings.shared.mdmEchoProtocolEnabled
            if oldValue != newValue {
                EchoProtocolUtil().enableEchoProtocol(enabled: newValue)
            }
        }
        if let oldValue = NSDictionary(dictionary: mdmDictionary)
            .value(forKey: AppSettings.keyPEPSaveEncryptedOnServerEnabled) as? Bool {
            let newValue = AppSettings.shared.mdmPEPSaveEncryptedOnServerEnabled
            if oldValue != newValue {
                TrustedServerUtil().setStoreSecurely(newValue: newValue)
            }
        }

        if let oldValues = NSDictionary(dictionary: mdmDictionary).value(forKey: AppSettings.keyPEPExtraKeys) as? [[String:String]] {
            let newValues = AppSettings.shared.mdmPEPExtraKeys
            if oldValues != newValues {
                MediaKeysUtil().configure(extraKeyDictionaries: newValues)
            }
        }

        // As ´Any´ does not conform to Equatable
        // we use NSDictionary to easily compare these dictionaries.
        let mdmSettingsHasChanged = !NSDictionary(dictionary: mdm).isEqual(to: mdmDictionary)
        if  mdmSettingsHasChanged {
            mdmDictionary = mdm
            NotificationCenter.default.post(name:.pEpMDMSettingsChanged, object: mdm, userInfo: nil)
        }
    }

    // MARK: - Deinit

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

