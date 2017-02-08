//
//  AppSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class AppSettings {
    static let reinitializePepOnNextStartup = "reinitializePepOnNextStartup"

    var shouldReinitializePepOnNextStartup: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppSettings.reinitializePepOnNextStartup)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppSettings.reinitializePepOnNextStartup)
        }
    }

    init() {
        registerDefaults()
    }

    func registerDefaults() {
        var defaults = [String: Any]()
        defaults[AppSettings.reinitializePepOnNextStartup] = false
        UserDefaults.standard.register(defaults: defaults)
    }
}
