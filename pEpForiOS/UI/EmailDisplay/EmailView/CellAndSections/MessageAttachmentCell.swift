//
//  AttachmentCell.swift
//  pEpForiOS
//
//  Created by Martín Brude on 20/11/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

class MessageAttachmentCell: UITableViewCell {
   @IBOutlet weak var attachmentView: AttachmentCellBackgroundView!
   @IBOutlet weak var fileExtensionLabel: UILabel!
   @IBOutlet weak var fileNameLabel: UILabel!
   @IBOutlet weak var iconImageView: UIImageView!
}
