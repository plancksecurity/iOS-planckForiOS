//
//  UserDefaults+MDM.swift
//  pEpForiOS
//
//  Created by Martín Brude on 2/9/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

// This extension is used to observe MDM settings via KVO.
//
// To do it, add an @objc dynamic var that has the same name as the UserDefaults key to observe.
// This allows to define the key path for observing.
// Observe the UserDefaults instance where the setting is stored.
//
// Usage example:
//    observer = userDefaults.observe(\.yourSetting, options: [.old, .new],
//      changeHandler: { (defaults, change) in
//      ...
//    })
//
// And don't forget to clean up:
//
//    deinit {
//        observer?.invalidate()
//    }
extension UserDefaults {

    @objc dynamic var mdmSettings: Dictionary<String, Any>? {
        return dictionary(forKey: MDMPredeployed.keyMDM)
    }
}
