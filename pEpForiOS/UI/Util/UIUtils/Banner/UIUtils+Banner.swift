//
//  UIUtils+Banner.swift
//  pEp
//
//  Created by Martín Brude on 3/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

extension UIUtils {

    /// Show the No internet connection banner error
    /// - Parameter viewController: The currently shown VC.
    public static func showNoInternetConnectionBanner(viewController : UIViewController? = nil) {
        let errorMessage = NSLocalizedString("You're offline", comment: "You're offline error message")
        NotificationBannerUtil.show(errorMessage: errorMessage, currentlyShownViewController: viewController)
    }

    /// Show the Server not available banner error
    public static func showServerNotAvailableBanner() {
        let errorMessage = NSLocalizedString("Server Unreachable", comment: "The server is not available error message")
        NotificationBannerUtil.show(errorMessage: errorMessage)
    }

    /// Hide any banner that is shown.
    /// - Parameter viewController: The currently shown VC.
    public static func hideBanner(viewController : UIViewController? = nil) {
        NotificationBannerUtil.hide(currentlyShownViewController: viewController)
    }
}

// MARK: - Private

extension UIUtils {

    /// Show an error banner.
    ///
    /// - Parameter error: The error to display
    private static func showBanner(errorMessage: String) {
        NotificationBannerUtil.show(errorMessage: errorMessage)
    }
}
