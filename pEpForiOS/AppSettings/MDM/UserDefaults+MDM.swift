//
//  UserDefaults+MDM.swift
//  pEpForiOS
//
//  Created by Martín Brude on 2/9/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UserDefaults {
    @objc dynamic var mdmSettings: Dictionary<String, Any>? {
        return dictionary(forKey: MDMPredeployed.keyMDM)
    }
}
