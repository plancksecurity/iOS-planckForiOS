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

    func messageCountPrefetch(completion: @escaping (Int)->()) -> PrefetchOperation {
       
        let prefetchOperation = PrefetchOperation { operation in
            MessageModel.perform {
                guard !operation.isCancelled,
                let message = self.message() else {
                    return
                }
                let messageCount = message.numberOfMessagesInThread()
                self.internalMessageCount = messageCount
                if (!operation.isCancelled){
                    DispatchQueue.main.async {
                        completion(messageCount)
                    }
                }
            }
        }
        return prefetchOperation
    }

    func bodyPeekPrefetch(for message: Message, completion: @escaping (String)->()) -> PrefetchOperation {

        let prefetchOperation = PrefetchOperation {operation in
            guard !operation.isCancelled else {
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
}
