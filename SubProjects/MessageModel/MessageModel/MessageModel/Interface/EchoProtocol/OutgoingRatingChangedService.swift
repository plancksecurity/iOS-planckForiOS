//
//  OutgoingRatingChangedService.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 07.09.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

/// Service for listening to outgoing rating changes, caused by the echo protocol.
///
/// Usage: Instantiate an instance of this class, and set the (weak) delegate.
class OutgoingRatingChangedService {
    /// Sets/unsets a delegate that gets informed about changes in outgoing message ratings.
    public func set(outgoingRatingChangedDelegate: OutgoingRatingChangedDelegate?) {
    }

    deinit {
        // TODO: Unset the delegate in any case
    }
}
