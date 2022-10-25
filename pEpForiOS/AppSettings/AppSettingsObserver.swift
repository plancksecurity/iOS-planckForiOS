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
        if let values = UserDefaults.standard.dictionary(forKey: MDMDeployment.keyMDM) {
            mdmDictionary = values
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsDidChange),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    // MARK: - Private

    /// The contents of the last MDM update.
    private var mdmDictionary: [String:Any] = [:]

    @objc private func userDefaultsDidChange(notification: NSNotification) {
        // We only care about standard user default settings, and specifically mdm settings
        guard let defaults = notification.object as? UserDefaults,
              defaults == UserDefaults.standard,
              let mdm = defaults.dictionary(forKey: MDMDeployment.keyMDM) else {
            // Nothing to do
            return
        }

        guard !NSDictionary(dictionary: mdm).isEqual(to: mdmDictionary) else {
            // No changes
            return
        }

        MediaKeysUtil().configure(mediaKeyDictionaries: AppSettings.shared.mdmMediaKeys)
        EchoProtocolUtil().enableEchoProtocol(enabled: AppSettings.shared.mdmEchoProtocolEnabled)
        TrustedServerUtil().setStoreSecurely(newValue: AppSettings.shared.mdmPEPSaveEncryptedOnServerEnabled)
        ExtraKeysUtil().configure(extraKeyDictionaries: AppSettings.shared.mdmPEPExtraKeys)

        mdmDictionary = mdm
        NotificationCenter.default.post(name:.pEpMDMSettingsChanged, object: mdm, userInfo: nil)
    }

    // MARK: - Deinit

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
