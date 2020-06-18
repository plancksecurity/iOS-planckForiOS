//
//  FolderTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 18/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {

    private var padding: CGFloat {
        if Device.isIphone5 {
            return 16.0
        }
        return 20.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard var frame = imageView?.frame, indentationWidth != 0 else {
            return
        }
        frame.origin.x = CGFloat(indentationLevel) * indentationWidth + padding
        imageView?.frame = frame
    }
}
