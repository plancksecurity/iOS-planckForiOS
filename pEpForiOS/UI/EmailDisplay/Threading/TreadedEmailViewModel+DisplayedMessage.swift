//
//  TreadedEmailViewModel+DisplayedMessage.swift
//  pEp
//
//  Created by Borja González de Pablo on 22/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension ThreadedEmailViewModel: DisplayedMessage {

    var messageModel: Message? {
       return messages.last
    }

    func update(forMessage message: Message) {
        updateInternal(message: message)
    }

}
