//
//  RecipientCellViewModel+FieldType.swift
//  pEp
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension RecipientCellViewModel {
    public enum FieldType: String {
        case to, cc, bcc

        func localizedTitle() -> String {
            switch self {
            case .to:
                return NSLocalizedString("To:", comment: "Compose field title")
            case .cc:
                return NSLocalizedString("CC:", comment: "Compose field title")
            case .bcc:
                return NSLocalizedString("BCC:", comment: "Compose field title")
            }
        }
    }
}
