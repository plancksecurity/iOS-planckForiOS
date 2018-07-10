//
//  EmailViewController+DisplayedMessage.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 31/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


extension EmailViewController: DisplayedMessage {

    var messageModel: Message? {
        return message
    }

    func update(forMessage message: Message) {
        self.message = message
        configureView()
    }

    func detailType() -> EmailDetailType {
        return EmailDetailType.single
    }

}
