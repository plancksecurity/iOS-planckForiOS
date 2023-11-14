//
//  NSNotificationName+Settings.swift
//  pEp
//
//  Created by Martín Brude on 20/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    /// Notification name to inform planckSyncActivityIndicator should change the state
    static public let planckSyncActivityIndicatorChanged = Notification.Name("security.planck.planckSyncActivityIndicatorChanged")
    
    /// Notification name to inform settings have changed.
    static public let planckSettingsChanged = Notification.Name("security.planck.planckSettingsChanged")
    
    /// Notification name to inform MDM settings have changed.
    static public let planckMDMSettingsChanged = Notification.Name("security.planck.planckMDMSettingsChanged")

}
