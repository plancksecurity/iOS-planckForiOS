//
//  MessageCell.swift
//
//  Created by Yves Landert on 16.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit

open class MessageCell: UITableViewCell {
    
    @IBOutlet weak public var titleLabel: UILabel?
    @IBOutlet weak public var valueLabel: UILabel?
    
    public var fieldModel: ComposeFieldModel?
    public var isExpanded = false
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    public func updateCell(_ model: ComposeFieldModel, _ indexPath: IndexPath) {
        fieldModel = model
        
        if titleLabel != nil {
            titleLabel?.text = fieldModel?.title
        }
    }
}
