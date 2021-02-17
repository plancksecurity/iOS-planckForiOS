//
//  TextAttachment.swift
//  pEp
//
//  Created by Andreas Buff on 30.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public class TextAttachment: NSTextAttachment {
    var attachment: Attachment?
    var identifier: String?
}
