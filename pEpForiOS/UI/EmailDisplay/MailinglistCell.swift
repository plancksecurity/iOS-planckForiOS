//
//  MailinglistCell.swift
//
//  Created by Yves Landert on 21.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit

import MessageModel

open class MailinglistCell: MessageCell {
    public override var height: CGFloat {
        didSet {
            if height != 0 {
                Log.warn(component: #function, content: "new height: \(height)")
            }
        }
    }
    public override func updateCell(_ model: ComposeFieldModel, _ message: Message) {
        height = 0
    }
}
