//
//  RecipientTextViewTextAttachment.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class RecipientTextViewTextAttachment: NSTextAttachment {
    public var recipient: Identity

    init(recipient: Identity) {
        self.recipient = recipient
        super.init(data: nil, ofType: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
