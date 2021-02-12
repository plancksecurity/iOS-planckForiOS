//
//  MessageCell.swift
//
//  Created by Yves Landert on 16.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit

import MessageModel

public protocol MessageCellDelegate: class {}

protocol MessageAttachmentDelegate {
    func didTap(cell: MessageCell, attachment: Attachment, location: CGPoint, inView: UIView?)
}

open class MessageCell: UITableViewCell {
    @IBOutlet weak public var titleLabel: UILabel?
    @IBOutlet weak public var valueLabel: UILabel?
    
    open weak var delegate: MessageCellDelegate?
    
    public var fieldModel: ComposeFieldModel?
    public var message: Message?
    public var height: CGFloat = UITableView.automaticDimension

    /**
     The current `IndexPath`, as last indicated via a call to `updateCell`.
     */

    override open func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    public func updateCell(model: ComposeFieldModel, message: Message) {
        fieldModel = model
        if titleLabel != nil {
            titleLabel?.text = fieldModel?.title
        }
    }
}
