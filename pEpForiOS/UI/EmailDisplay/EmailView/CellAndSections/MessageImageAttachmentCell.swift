//
//  MessageImageAttachmentCell.swift
//  pEp
//
//  Created by Martín Brude on 4/3/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

class MessageImageAttachmentCell: UITableViewCell {

    @IBOutlet weak var imageAttachmentView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        // Normally this wouldn't be the right place to clean up content related stuff
        // But as this image is set asyncronously, we don't want to show the wrong image.
        imageAttachmentView.image = nil
    }
}
