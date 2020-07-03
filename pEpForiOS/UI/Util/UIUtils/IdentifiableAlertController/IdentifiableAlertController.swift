//
//  IdentifiableAlertController.swift
//  pEp
//
//  Created by Andreas Buff on 01.07.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension IdentifiableAlertController {
    enum Identifier {
        case passphraseAlert
        case other
    }
}

/// Subclass of UIAlertController for the sole purpose of providing an identifier.
/// Use this class instead of UIAlertController if you need to identify the alert. For instance
/// when you have to check if an alert of this type is already shown.
class IdentifiableAlertController: UIAlertController {
    public private(set) var identifier = Identifier.other

    public convenience init(identifier: IdentifiableAlertController.Identifier = .other,
                            title: String?,
                            message: String?,
                            preferredStyle: UIAlertController.Style) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        self.identifier = identifier
    }
}
