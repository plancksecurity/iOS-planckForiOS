//
//  Attachment+InlinedImage.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.03.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

extension Attachment {
    public func inlinedText(scaleToImageWidth: CGFloat,
                            attachmentWidth: CGFloat) -> NSAttributedString {
        guard let theImage = image else {
            Log.shared.errorAndCrash("No image")
            return NSAttributedString()
        }

        // Workaround: If the image has a higher resolution than that, UITextView has serious
        // performance issues (delay typing).
        guard let scaledImage = theImage.resized(newWidth: scaleToImageWidth, useAlpha: false) else {
            Log.shared.errorAndCrash("Error resizing")
            return NSAttributedString()
        }

        let textAttachment = BodyCellViewModel.TextAttachment()
        textAttachment.image = scaledImage
        textAttachment.attachment = self
        textAttachment.bounds = CGRect.rect(withWidth: attachmentWidth,
                                            ratioOf: scaledImage.size)
        let imageString = NSAttributedString(attachment: textAttachment)
        return imageString
    }
}
