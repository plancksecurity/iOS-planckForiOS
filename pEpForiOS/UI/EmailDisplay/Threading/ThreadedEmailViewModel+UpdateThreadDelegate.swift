//
//  ThreadedEmailViewModel+UpdateThreadDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 18/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension ThreadedEmailViewModel: UpdateThreadListDelegate {

    func deleted(message: Message) {
        guard let index = indexOfMessage(message: message) else {
            return
        }
        messages.remove(at: index)
        delegate?.emailViewModel(viewModel: self, didRemoveDataAt: index)
    }

    func updated(message: Message) {
        guard let index = indexOfMessage(message: message) else {
            return
        }
        messages[index] = message
        delegate?.emailViewModel(viewModel: self, didUpdateDataAt: index)
    }

    func added(message: Message) {
        messages.append(message)
        delegate?.emailViewModel(viewModel: self, didInsertDataAt: (messages.count - 1))
    }

    fileprivate func indexOfMessage(message: Message)-> Int? {
        for  i in 0...messages.count {
            if messages[i] == message{
                return i
            }
        }
        return nil
    }
}
