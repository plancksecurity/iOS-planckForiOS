//
//  UIUtils+Banner.swift
//  pEp
//
//  Created by Martín Brude on 3/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIUtils {

    /// Show an error banner.
    ///
    /// - Parameter error: The error to display
    static func showBanner(error: DisplayUserError) {
        NotificationBannerUtil.show(error: error)
    }
}
