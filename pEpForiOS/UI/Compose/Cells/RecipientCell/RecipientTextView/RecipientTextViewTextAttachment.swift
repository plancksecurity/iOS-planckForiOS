//
//  RecipientTextViewTextAttachment.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class RecipientTextViewTextAttachment: NSTextAttachment {
    public var recipient: Identity
    public var fontDescender: CGFloat?

    init(recipient: Identity) {
        self.recipient = recipient
        super.init(data: nil, ofType: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Makes sure text aligns with text attachment.
    // From: http://petehare.com/inline-nstextattachment-rendering-in-uitextview/
    public override func attachmentBounds(for textContainer: NSTextContainer?,
                                          proposedLineFragment lineFrag: CGRect,
                                          glyphPosition position: CGPoint,
                                          characterIndex charIndex: Int) -> CGRect {
        var superRect = super.attachmentBounds(for: textContainer,
                                               proposedLineFragment: lineFrag,
                                               glyphPosition: position,
                                               characterIndex: charIndex)
        if let descender = fontDescender {
            superRect.origin.y = descender
        }
        return superRect
    }
}
