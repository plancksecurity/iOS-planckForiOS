//
//  HtmlToAttributedTextSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

import MessageModel

public protocol HtmlToAttributedTextSaxParserAttachmentDelegate: class {
    func imageAttachment(src: String?, alt: String?) -> Attachment?
}
