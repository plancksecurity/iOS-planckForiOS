//
//  NSNotificationName+OutgoingRatingChange.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.09.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

extension Notification.Name {
    /// Notification name to inform changes in outgoing ratings (via echo protocol).
    static public let outgoingRatingChanged = Notification.Name("security.pEp.outgoingRatingChanged")
}
