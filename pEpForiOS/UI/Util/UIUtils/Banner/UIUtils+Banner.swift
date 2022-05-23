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
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

extension UIUtils {

    /// Show the No internet connection banner error
    public static func showNoInternetConnectionBannerOn(sharingExtensionComposeViewController: ComposeViewController) {
        let errorMessage = NSLocalizedString("You're offline", comment: "You're offline error message")
        NotificationBannerUtil.show(errorMessage: errorMessage,
                                    sharingExtensionComposeViewController: sharingExtensionComposeViewController)
    }

    /// Show the No internet connection banner error
    public static func showNoInternetConnectionBanner() {
        let errorMessage = NSLocalizedString("You're offline", comment: "You're offline error message")
        NotificationBannerUtil.show(errorMessage: errorMessage)
    }

    /// Show the Server not available banner error
    public static func showServerNotAvailableBanner() {
        let errorMessage = NSLocalizedString("Server Unreachable", comment: "The server is not available error message")
        NotificationBannerUtil.show(errorMessage: errorMessage)
    }

    /// Hide any banner that is shown.
    public static func hideBanner() {
        NotificationBannerUtil.hide()
    }

    /// Hide any banner that is shown.
    public static func hideBannerOn(sharingExtensionComposeViewController: ComposeViewController) {
        NotificationBannerUtil.hide(sharingExtensionComposeViewController: sharingExtensionComposeViewController)
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
