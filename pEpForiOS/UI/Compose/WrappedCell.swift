//
//  WrappedCell.swift
//  pEp
//
//  Created by Borja González de Pablo on 12/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class WrappedCell: ComposeCell {
    var ccEnabled = false

    // MARK: - Public Methods

    public final func expand() -> Bool {
        if !isExpanded {
            isExpanded = !isExpanded
            textView.isHidden = true
            titleLabel?.text = fieldModel?.title

            if isExpanded {
                textView.isHidden = false

                titleLabel?.text = fieldModel?.expandedTitle
            }
        }
        return isExpanded
    }

    override func shouldDisplay()-> Bool {
        return fieldModel?.display == .always || !ccEnabled
    }
}
