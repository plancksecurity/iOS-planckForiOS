//
//  UIUtils+SwiftMessages.swift
//  pEp
//
//  Created by Martín Brude on 27/4/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
import SwiftMessages
import UIKit

extension UIUtils {

    /// Show an non modal alert view to inform about an SMTP error
    /// - Parameter error: The error to get related info to display.
    public static func showSMTPErrorMessage(error: DisplayUserError) {
        guard let info = error.extraInfo else {
            return
        }
        let view = MessageView.viewFromNib(layout: .messageView)
        let title = NSLocalizedString("Server Unreachable", comment: "Server Unreachable - warning title")
        let body = NSLocalizedString("We could not connect to the SMTP server.\n\(info)",
                                     comment: "Server Unreachable - warning message")
        let buttonTitle = NSLocalizedString("Copy Log", comment: "Copy Log Button Title")
        let accessibilityPrefix = NSLocalizedString("Warning", comment:"Warning accessibility Prefix")
        view.configureTheme(.error, iconStyle: .none)
        view.accessibilityPrefix =  accessibilityPrefix
        view.configureContent(title: title,
                              body: body,
                              iconImage: nil,
                              iconText: nil,
                              buttonImage: nil,
                              buttonTitle: buttonTitle,
                              buttonTapHandler: { _ in
            UIPasteboard.general.string = info
            swiftMessages.hide()
        })

        // Hide when message view is tapped
        view.tapHandler = { _ in SwiftMessages.hide() }

        // Increase the external margin around the card. In general, the effect of this setting
        // depends on how the given layout is constrained to the layout margins.
        view.layoutMarginAdditions = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        // Show the message.
        swiftMessages.show(view: view)
    }
}
