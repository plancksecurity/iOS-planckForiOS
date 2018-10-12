//
//  RecipientCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol RecipientCellViewModelDelegate {
    //IOS-1369: TODO
}

class RecipientCellViewModel: CellViewModel {
    public let title: String
    public var content = NSMutableAttributedString(string: "")
    public let type: FieldType
    private var recipients = [Identity]()

    init(type: FieldType, recipients: [Identity] = []) {
        self.type = type
        self.recipients = recipients
        self.title = type.localizedTitle()
    }
}

extension RecipientCellViewModel {
    public enum FieldType: String {
        case to, cc, bcc, wraped

        func localizedTitle() -> String {
            switch self {
            case .to:
                return NSLocalizedString("To:", comment: "Compose field title")
            case .cc:
                return NSLocalizedString("CC:", comment: "Compose field title")
            case .bcc:
                return NSLocalizedString("BCC:", comment: "Compose field title")
            case .wraped:
                return NSLocalizedString("Cc/Bcc:", comment: "Compose field title")
            }
        }
    }
}
