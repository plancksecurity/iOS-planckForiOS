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

    func deleted(message: Message){
        deleted(topMessage: message)
    }

    func deleted(topMessage message: Message) {
        guard let index = indexOfMessage(message: message) else {
            return
        }
        messages.remove(at: index)
        delegate?.emailViewModel(viewModel: self, didRemoveDataAt: index)
    }

    func updated(message: Message) {
        DispatchQueue.main.async {
            self.updateInternal(message: message)
        }
    }

    func added(message: Message) {
        let index = addMessage(message: message)
        delegate?.emailViewModel(viewModel: self, didInsertDataAt: index)
    }
}
