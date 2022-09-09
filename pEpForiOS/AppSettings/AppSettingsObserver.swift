//
//  AppSettingsObserver.swift
//  pEp
//
//  Created by Martín Brude on 7/9/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

class AppSettingsObserver {

    static public let shared = AppSettingsObserver()

    // MARK: - Private

    private var mdmDictionary: [String: Any] = [:]

    private init() {
        startObserver()
    }

    private func startObserver() {
        if let values = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) {
            mdmDictionary = values
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsDidChange),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    @objc private func userDefaultsDidChange(notification: NSNotification) {
        // We only care about standard user default settings, and specifically mdm settings
        guard let defaults = notification.object as? UserDefaults,
              defaults == UserDefaults.standard,
              let mdm = defaults.dictionary(forKey: MDMPredeployed.keyMDM) else {
            //Nothing to do
            return
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

