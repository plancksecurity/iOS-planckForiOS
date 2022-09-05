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
// To do it, we add the property with @objc dynamic modifiers,
// then we use the variable name as keypath.
//
// Usage example:
//    userDefaults.observe(\.mdmSettings, options: [.old, .new],
//      changeHandler: { (defaults, change) in
//    })
extension UserDefaults {
    @objc dynamic var mdmSettings: Dictionary<String, Any>? {
        return dictionary(forKey: MDMPredeployed.keyMDM)
    }
}
