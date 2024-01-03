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
/// Helper extension to relate a status from the engine to UI assets, if any exist
extension Rating {
    /// The icon suitable for indicating the pEp rating of a message.
    ///
    /// - Parameter enabled: whether or not pEp protection is enabled
    /// - Returns: icon suitable for indicating the pEp rating of a message
    public func statusIconForMessage(enabled: Bool = true, withText : Bool = true, isSMime: Bool) -> UIImage? {
        if isSMime {
            return UIImage(named: "planck-inactive")
        }
        switch self {
        case .undefined, .fullyAnonymous, .haveNoKey:
            return nil
        case .cannotDecrypt:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-cannot-decrypt") : UIImage(named: "pEp-status-cannot-decrypt")
            } else {
                return nil
            }
        case .unencrypted:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-not-encrypted") : UIImage(named: "pEp-status-weakly-encrypted")
            } else {
                return nil
            }
        case .mediaKeyEncryption:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-encrypted-yellow") : UIImage(named: "pEp-status-weakly-encrypted")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
        case .unreliable:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-weak-encryption") : UIImage(named: "pEp-status-weakly-encrypted")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
        case .reliable:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-encrypted-green") : UIImage(named: "pEp-status-encrypted")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
        case .trusted, .trustedAndAnonymized:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-trusted") : UIImage(named: "pEp-status-trusted")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
        case .mistrust:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-dangerous-circle") : UIImage(named: "pEp-status-dangerous-circle")
            } else {
                return nil
            }
        case .b0rken, .underAttack:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-dangerous-triangle") : UIImage(named: "pEp-status-dangerous-triangle")
            } else {
                return nil
            }

        }
    }
}
