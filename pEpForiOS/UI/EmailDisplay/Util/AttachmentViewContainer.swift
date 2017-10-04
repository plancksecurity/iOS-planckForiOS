//
//  AttachmentViewContainer.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

struct AttachmentViewContainer {
    let view: UIView
    let attachment: Attachment

    /** Should this be displayed as an image inline (that is, is the view an `UIImageView`)? */
    let isInlineImage: Bool
}
