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
        let messageOperation = messageCountPrefetch(completion: { count in
            self.internalMessageCount = count
        })
        if(!messageOperation.isFinished){
            queue.addOperation(messageOperation)
        }
    }
    func cancelLoad() {
        queue.cancelAllOperations()
    }

    func messageCountPrefetch(completion: @escaping (Int)->()) -> PrefetchOperation {
       
        let prefetchOperation = PrefetchOperation {
            MessageModel.perform {
                let messageCount = self.message.numberOfMessagesInThread()
                DispatchQueue.main.async {
                    completion(messageCount)
                }
            }
        }
        prefetchOperation.qualityOfService = .userInitiated
        return prefetchOperation
    }
}
