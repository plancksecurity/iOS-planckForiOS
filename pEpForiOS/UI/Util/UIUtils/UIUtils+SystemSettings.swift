//
//  UIUtils+SystemSettings.swift
//  pEp
//
//  Created by Martín Brude on 22/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIUtils {

    /// Open iOS settings if possible.
    public static func openSystemSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
            })
        }
    }
}
