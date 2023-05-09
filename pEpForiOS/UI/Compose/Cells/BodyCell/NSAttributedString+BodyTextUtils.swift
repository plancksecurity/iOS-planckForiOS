//
//  NSAttributedString+BodyTextUtils.swift
//  pEp
//
//  Created by Andreas Buff on 30.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

// MARK: - BodyTextUtils

extension NSAttributedString {

    public func assureMaxTextAttachmentImageWidth(_ maxWidth: CGFloat) {
        for textAttachment in textAttachments() {
            guard let image = textAttachment.image else {
                Log.shared.errorAndCrash("No image?")
                return
            }
            if image.size.width > maxWidth {
                textAttachment.image = image.resized(newWidth: maxWidth)
            }
        }
    }
}
