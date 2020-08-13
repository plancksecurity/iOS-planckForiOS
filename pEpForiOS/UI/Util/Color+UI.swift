//
//  Color+UI.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

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
}
