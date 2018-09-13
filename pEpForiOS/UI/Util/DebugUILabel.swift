//
//  DebugUILabel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class DebugUILabel: UILabel {
    override var text: String? {
        didSet {
            print("*** new text \"\(text ?? "nil")\"")
        }
    }
}
