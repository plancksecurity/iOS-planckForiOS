//
//  EchoProtocolUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 12/9/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter_iOS
import PEPObjCTypes_iOS

/// https://dev.pep.foundation/Engine/Media%20keys
public protocol EchoProtocolUtilProtocol: AnyObject {

    /// Enables or disable the use of the echo protocol.
    ///
    /// The protocol is enabled by default.
    func enableEchoProtocol(enabled: Bool)

    /// Enables or disables pings for the engine's `outgoing_message_rating_preview`.
    ///
    /// Ping messages from outgoing_message_rating_preview are enabled by default.
    func configureEchoInOutgoingMessageRatingPreviewEnabled(enabled: Bool)
}

public class EchoProtocolUtil: EchoProtocolUtilProtocol {

    /// Expose the init outside MM.
    public init() {}

    public func enableEchoProtocol(enabled: Bool) {
        PEPObjCAdapter.setEchoEnabled(enabled)
    }

    public func configureEchoInOutgoingMessageRatingPreviewEnabled(enabled: Bool) {
        PEPObjCAdapter.setEchoInOutgoingMessageRatingPreviewEnabled(enabled)
    }
}


