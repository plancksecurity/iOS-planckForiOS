//
//  TrustedServerUtils.swift
//  pEp
//
//  Created by Andreas Buff on 19.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    public var isOnTrustedServer: Bool {
        return parent.account.server(with: .imap)?.trusted ?? false
    }

//    public var isOutgoing: Bool {
//        return from?.address == parent.account.user.address ||
//            //Theoretical case. Should never happen as we never save messages without from to drafts
//            (from == nil && parent.folderType == .drafts)
//    }
//
//    public var isIncomming: Bool {
//        return !isOutgoing
//    }

}
