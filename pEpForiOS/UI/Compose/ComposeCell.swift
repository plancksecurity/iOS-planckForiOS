//
//  MailComposerCell.swift
//  MailComposer
//
//  Created by Yves Landert on 14.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit

open class ComposeCell: UITableViewCell, CellProtocol {
    
    @IBOutlet weak public var textView: ComposeTextView!
    @IBOutlet weak public var titleLabel: UILabel?

    open weak var delegate: ComposeCellDelegate?

    public var index: IndexPath!
    public var fieldModel: ComposeFieldModel?
    public var isExpanded = false
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none        
    }

    public func updateCell(_ model: ComposeFieldModel, _ indexPath: IndexPath) {
        index = indexPath
        fieldModel = model
        textView.fieldModel = model
        
        if titleLabel != nil {
            titleLabel?.text = fieldModel?.title
        }
    }
}

extension ComposeCell: UITextViewDelegate {
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        delegate?.textdidStartEditing(at: index, textView: cmTextview)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        fieldModel?.value = cmTextview.attributedText
        delegate?.textdidChange(at: index, textView: cmTextview)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        delegate?.textDidEndEditing(at: index, textView: cmTextview)
    }
}


