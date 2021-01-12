//
//  TwoLinesButton.swift
//  pEp
//
//  Created by Martín Brude on 12/1/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

/// This introduce a line break by replacing the first whitespace with a line break.
class TwoLinesButton : UIButton {
    override func setTitle(_ title: String?, for state: UIControl.State) {
        let newTitle = title?.replaceFirst(of: " ", with: "\n")
        super.setTitle(newTitle, for: state)
    }
}
