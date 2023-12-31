//
//  MDMUtil.swift
//  pEpForiOS
//
//  Created by Martín Brude on 13/10/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

public class MDMUtil {

    /// Indicates if MDM is enabled.
    ///
    /// This configuration can be found in the Configuration folder.
    /// It may vary from release to debug builds.
    ///
    /// - Returns: True, if MDM is enabled. False otherwise.
    static func isEnabled() -> Bool {
        guard let mdmEnabled = Bundle.main.infoDictionary?["MDM_ENABLED"] as? String else {
            return false
        }
        return (mdmEnabled as NSString).boolValue
    }
}
