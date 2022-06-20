//
//  HtmlToAttributedTextSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public protocol HtmlToAttributedTextSaxParserAttachmentDelegate: AnyObject {
    func imageAttachment(src: String?, alt: String?) -> Attachment?
}
