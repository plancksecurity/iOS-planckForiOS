//
//  Color+UI.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension Color {
    /// The icon suitable for indicating the pEp rating of a message.
    ///
    /// - Parameter enabled: whether or not pEp protection is enabled
    /// - Returns: icon suitable for indicating the pEp rating of a message
    func statusIconForMessage(enabled: Bool = true, withText : Bool = true) -> UIImage? {
        switch self {
        case .noColor:
            return nil
        case .red:
            return withText ? UIImage(named: "pEp-status-msg-red") : UIImage(named: "pEp-status-red_white-border")
        case .yellow:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-yellow") : UIImage(named: "pEp-status-yellow_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .green:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-green") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
        }
    }

    /// Similar to `statusIcon`, but for a message in a local folder and embedded
    /// in the contact's profile picture.
    /// Typically includes a white border, and doesn't support disabled protection.
    func statusIconInContactPicture() -> UIImage? {
        switch self {
        case .noColor:
            return nil
        case .red:
            return UIImage(named: "pEp-status-red_white-border")
        case .yellow:
            return UIImage(named: "pEp-status-yellow_white-border")
        case .green:
            return UIImage(named: "pEp-status-green_white-border")
        }
    }
}
