//
//  EchoProtocolUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 12/9/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter_iOS
import PEPObjCTypes

/// https://dev.pep.foundation/Engine/Media%20keys
public class EchoProtocolUtil {

    /// Expose the init outside MM.
    public init() {}

    /// Enables or disable the use of the echo protocol.
    ///
    /// The protocol is enabled by default.
    public func enableEchoProtocol(enabled: Bool) {
        PEPObjCAdapter.setEchoEnabled(enabled)
    }
}
