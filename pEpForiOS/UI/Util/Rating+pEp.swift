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
        case .undefined:
            return nil
        case .cannotDecrypt:
            return withText ? UIImage(named: "pEp-status-msg-red") : UIImage(named: "pEp-status-red_white-border")
        case .haveNoKey:
            return withText ? UIImage(named: "pEp-status-msg-red") : UIImage(named: "pEp-status-red_white-border")
        case .unencrypted: //I think this is nil?
            return nil
        case .mediaKeyEncryption: // AKA Basic Protection
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-basic-protection") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .unreliable: // AKA Weak protection
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-weak-protection") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .b0rken:
            return nil
        case .reliable:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-yellow") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .trusted:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-yellow") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .trustedAndAnonymized:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-green") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
        case .fullyAnonymous:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-green") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
        case .mistrust:
            return withText ? UIImage(named: "pEp-status-msg-red") : UIImage(named: "pEp-status-red_white-border")
        case .underAttack:
            return withText ? UIImage(named: "pEp-status-msg-red") : UIImage(named: "pEp-status-red_white-border")
        }
    }

    /// Similar to `statusIcon`, but for a message in a local folder and embedded
    /// in the contact's profile picture.
    /// Typically includes a white border, and doesn't support disabled protection.
}
