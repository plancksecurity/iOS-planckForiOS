//
//  OpenMessage.swift
//  pEp
//
//  Created by Borja González de Pablo on 12/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class FullyDisplayedMessage: PreviewMessage {

    var body: String

    override init(withMessage msg: Message) {
        body = msg.longMessage ?? ""
        super.init(withMessage: msg)
    }
}
