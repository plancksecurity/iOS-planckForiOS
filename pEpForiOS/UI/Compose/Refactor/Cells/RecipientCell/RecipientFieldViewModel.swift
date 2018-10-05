//
//  RecipientFieldViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class RecipientFieldViewModel {
    public let title: String
    public var content: NSAttributedString
    private var recipients = [Identity]()

    init(title: String, content: NSAttributedString) {
        self.title = title
        self.content = content
    }
}
