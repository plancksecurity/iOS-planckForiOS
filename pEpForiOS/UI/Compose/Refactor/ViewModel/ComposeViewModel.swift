//
//  ComposeViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

//IOS-1369: VMs should conform, *not* VCs (as implemented by me)
protocol ComposeViewModelResultDelegate: class {
    /// Called after a valid mail has been composed and saved for sending.
    func composeViewModelDidComposeNewMail()
    /// Called after saving a modified version of the original message.
    /// (E.g. after editing a drafted message)
    func composeViewModelDidModifyMessage()
    /// Called after permanentaly deleting the original message.
    /// (E.g. saving an edited oubox mail to drafts. It's permanentaly deleted from outbox.)
    func composeViewModelDidDeleteMessage()
}

protocol ComposeViewModelDelegate: class {
    //Will grow BIG :-/
    //IOS-1369: //TODO handle func userSelectedRecipient(identity: Identity)
}

class ComposeViewModel {
    weak var resultDelegate: ComposeViewModelResultDelegate?
    weak var delegate: ComposeViewModelDelegate?

    /// Recipient to set as "To:".
    /// Is ignored if a originalMessage is set.
    var prefilledTo: Identity?
    /// Original message to compute content and recipients from (e.g. a message we reply to).
    var originalMessage: Message?

    init(resultDelegate: ComposeViewModelResultDelegate? = nil, originalMessage: Message? = nil) {
        self.resultDelegate = resultDelegate
        self.originalMessage = originalMessage
    }
}

 // MARK: - SuggestTableViewController

extension ComposeViewModel: SuggestViewModelResultDelegate {
    func suggestViewModelDidSelectContact(identity: Identity) {
        //IOS-1369:
        //TODO:
    }
}
