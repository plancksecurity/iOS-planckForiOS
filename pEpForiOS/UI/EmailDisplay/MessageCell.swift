//
//  MessageCell.swift
//
//  Created by Yves Landert on 16.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

public protocol MessageCellDelegate: class {}

public protocol MessageContentCellDelegate: MessageCellDelegate {
    func didUpdate(cell: MessageCell, height: CGFloat)
}

open class MessageCell: UITableViewCell {
    @IBOutlet weak public var titleLabel: UILabel?
    @IBOutlet weak public var valueLabel: UILabel?
    
    open weak var delegate: MessageCellDelegate?
    
    public var fieldModel: ComposeFieldModel?
    public var message: Message?
    public var isExpanded = false
    public var height: CGFloat = UITableViewAutomaticDimension

    /**
     The current `IndexPath`, as last indicated via a call to `updateCell`.
     */
    public var indexPath: IndexPath?
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    public func updateCell(model: ComposeFieldModel, message: Message, indexPath: IndexPath) {
        height = UITableViewAutomaticDimension // reset height to default
        fieldModel = model
        if titleLabel != nil {
            titleLabel?.text = fieldModel?.title
        }
        self.indexPath = indexPath
    }
}
