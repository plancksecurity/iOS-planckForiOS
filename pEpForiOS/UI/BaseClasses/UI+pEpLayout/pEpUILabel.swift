//
//  pEpUILabel.swift
//  pEp
//
//  Created by Adam Kowalski on 21/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class pEpUILabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
}

// MARK: - Private

extension pEpUILabel {
    private func setUp() {
        pEpSetFontFace()
    }
}
