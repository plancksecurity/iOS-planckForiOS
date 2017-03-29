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
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    public func updateCell(_ model: ComposeFieldModel, _ message: Message) {
        height = UITableViewAutomaticDimension // reset height to default
        fieldModel = model
        if titleLabel != nil {
            titleLabel?.text = fieldModel?.title
        }
    }
}
