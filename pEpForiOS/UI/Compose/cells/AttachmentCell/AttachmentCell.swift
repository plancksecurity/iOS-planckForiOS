//
//  AttachmentCell.swift
//  pEp
//
//  Created by Andreas Buff on 27.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import SwipeCellKit

//IOS-1369: Old & new are currently using it !! (move to refactor group when done).
class AttachmentCell: SwipeTableViewCell {
    static let storyboardID = "AttachmentCell"
    static let preferredHigh: CGFloat = 114.0

    @IBOutlet weak var fileName: UILabel!

    @IBOutlet weak var fileExtension: UILabel!

    override func prepareForReuse() {
        fileName.text = ""
        fileExtension.text = ""
    }
}
