// Message threadding is currently umsupported. The code might be helpful.

////
////  ThreadedEmailViewModel+MoveToFolderDelegate.swift
////  pEp
////
////  Created by Borja González de Pablo on 27/06/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//import MessageModel
//
//extension ThreadedEmailViewModel: MoveToFolderDelegate{
//    func didmove(messages: [Message]) {
//        didMove()
//    }
//
//    func didMove() {
//        guard let lastMessage = messages.last else {
//            return
//        }
//        emailDisplayDelegate?.emailDisplayDidDelete(message: lastMessage)
//    }
//}
