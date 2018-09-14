//
//  MessageViewModel+PrefetchableViewModel.swift
//  pEp
//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension MessageViewModel: PrefetchableViewModel {

    func loadData() {
//        let summaryOperation = bodyPeekPrefetch(completion: { sumary in
//            self.internalBoddyPeek = sumary
//        })
//        if(!summaryOperation.isFinished){
//            queue.addOperation(summaryOperation)
//        }
//        let messageOperation = messageCountPrefetch(completion: { count in
//            self.internalMessageCount = count
//        })
//        if(!messageOperation.isFinished){
//            queue.addOperation(messageOperation)
//        }
    }

    func messageCountPrefetch(completion: @escaping (Int)->()) -> SelfReferencingOperation {
       
        let prefetchOperation = SelfReferencingOperation {  [weak self] operation in
            guard let me = self else {
                return
            }
            MessageModel.performAndWait {
                guard
                    let operation = operation,
                    !operation.isCancelled,
                let message = me.message() else {
                    return
                }
                let messageCount = message.numberOfMessagesInThread()
                me.internalMessageCount = messageCount
                if (!operation.isCancelled){
                    DispatchQueue.main.async {
                        completion(messageCount)
                    }
                }
            }
        }
        return prefetchOperation
    }

    func bodyPeekPrefetch(for message: Message, completion: @escaping (String)->()) -> SelfReferencingOperation {

        let prefetchOperation = SelfReferencingOperation {operation in
            guard
                let operation = operation,
                !operation.isCancelled else {
                return
            }
            MessageModel.performAndWait {
                guard !operation.isCancelled else {
                    return
                }
                let summary = MessageViewModel.getSummary(fromMessage: message)
                self.internalBoddyPeek = summary
                if(!operation.isCancelled){
                    DispatchQueue.main.async {
                        completion(summary)
                    }
                }
            }
        }
        return prefetchOperation
    }

    func getSecurityBadgeOperation(
        completion: @escaping (UIImage?) -> ()) -> SelfReferencingOperation {
        let prefetchOperation = SelfReferencingOperation { [weak self] operation in
            guard let me = self else {
                return
            }
            MessageModel.performAndWait {
                guard
                    let operation = operation,
                    !operation.isCancelled,
                    let message = me.message() else {
                        return
                }

                if (!operation.isCancelled) {
                    me.profilePictureComposer.securityBadge(for: message, completion: completion)
                }
            }
        }
        return prefetchOperation
    }

}
