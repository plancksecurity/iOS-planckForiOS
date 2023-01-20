//
//  EnterpriseUtil.swift
//  pEpForiOS
//
//  Created by Martín Brude on 19/1/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

public class EnterpriseUtil {

    /// Indicates if the build is for Enterprise.
    ///
    /// This configuration can be found in the Configuration folder.
    /// It may vary from release to debug builds.
    ///
    /// - Returns: True, if the build is for enterprise. False otherwise.
    static func isEnterprise() -> Bool {
        guard let isEnterprise = Bundle.main.infoDictionary?["IS_ENTERPRISE"] as? String else {
            return false
        }
        return (isEnterprise as NSString).boolValue
    }
}
