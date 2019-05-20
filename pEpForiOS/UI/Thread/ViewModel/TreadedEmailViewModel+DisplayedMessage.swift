// Message threadding is currently umsupported. The code might be helpful.

////
////  TreadedEmailViewModel+DisplayedMessage.swift
////  pEp
////
////  Created by Borja González de Pablo on 22/06/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//import MessageModel
//
//extension ThreadedEmailViewModel: DisplayedMessage {
//
//    var messageModel: Message? {
//       return tip
//    }
//
//    func update(forMessage message: Message) {
//        updateInternal(message: message)
//        if message == currentDisplayedMessage?.messageModel {
//            currentDisplayedMessage?.update(forMessage: message)
//        }
//    }
//
//    func detailType() -> EmailDetailType {
//        return EmailDetailType.thread
//    }
//}
