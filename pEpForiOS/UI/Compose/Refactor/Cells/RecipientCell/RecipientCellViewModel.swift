//
//  RecipientCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol RecipientCellViewModelResultDelegate {
    //IOS-1369: TODO
}

protocol RecipientCellViewModelDelegate {
    //IOS-1369: TODO
}

class RecipientCellViewModel: CellViewModel {
    public let title: String
    public var content = NSMutableAttributedString(string: "")
    public let type: FieldType
    private var initialRecipients = [Identity]()

    init(type: FieldType, recipients: [Identity] = []) {
        self.type = type
        self.initialRecipients = recipients
        self.title = type.localizedTitle()
    }
}
