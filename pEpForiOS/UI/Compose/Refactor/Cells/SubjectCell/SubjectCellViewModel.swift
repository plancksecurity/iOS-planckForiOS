//
//  SubjectCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol SubjectCellViewModelDelegate {
    //IOS-1369: TODO
}

class SubjectCellViewModel: CellViewModel {
    let minHeigth: CGFloat = 58.0
    public let title = NSLocalizedString("Subject:",
                                         comment:
        "Title of subject field when composing a message")
    public var content: NSMutableAttributedString = NSMutableAttributedString(string: "")
    private var recipients = [Identity]()
}
