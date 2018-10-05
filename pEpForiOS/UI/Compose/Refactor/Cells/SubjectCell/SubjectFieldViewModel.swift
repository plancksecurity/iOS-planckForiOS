//
//  SubjectFieldViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class SubjectFieldViewModel {
    public let title = NSLocalizedString("Subject:",
                                         comment:
        "Title of of subject field when composing a message")
    public var content: NSMutableAttributedString = NSMutableAttributedString(string: "")
    private var recipients = [Identity]()
}
