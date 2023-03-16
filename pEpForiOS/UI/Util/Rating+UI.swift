//
//  Rating+pEp.swift
//  pEp
//
//  Created by Sascha Bacardit on 10/3/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension Rating {
    /// The icon suitable for indicating the pEp rating of a message.
    ///
    /// - Parameter enabled: whether or not pEp protection is enabled
    /// - Returns: icon suitable for indicating the pEp rating of a message
    public func statusIconForMessage(enabled: Bool = true, withText : Bool = true) -> UIImage? {
        switch self {
        case .undefined, .fullyAnonymous, .haveNoKey:
            return nil
        case .cannotDecrypt:
            return withText ? UIImage(named: "pEp-status-msg-cannot-decrypt") : UIImage(named: "pEp-status-cannot-decrypt")
        case .unencrypted:
            return withText ? UIImage(named: "pEp-status-msg-not-encrypted") : UIImage(named: "pEp-status-red_white-border")
        case .mediaKeyEncryption:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-basic-protection") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .unreliable:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-weak-encryption") : UIImage(named: "pEp-status-weakly-encrypted")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .reliable:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-encrypted-green") : UIImage(named: "pEp-status-encrypted")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .trusted, .trustedAndAnonymized:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-trusted") : UIImage(named: "pEp-status-trusted")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .mistrust:
            return withText ? UIImage(named: "pEp-status-msg-dangerous-circle") : UIImage(named: "pEp-status-dangerous-circle")
        case .b0rken, .underAttack:
            return withText ? UIImage(named: "pEp-status-msg-dangerous-triangle") : UIImage(named: "pEp-status-dangerous-triangle")

        }
    }

    /// Similar to `statusIcon`, but for a message in a local folder and embedded
    /// in the contact's profile picture.
    /// Typically includes a white border, and doesn't support disabled protection.
}
