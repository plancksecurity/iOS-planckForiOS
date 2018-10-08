//
//  AccountFieldViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class AccountFieldViewModel: CellViewModel {
    let minHeigth: CGFloat = 64.0
    public let title = NSLocalizedString("From:",
                                         comment:
        "Title of account picker when composing a message")
    public var content: NSMutableAttributedString = NSMutableAttributedString(string: "")
}
