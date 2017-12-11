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

    public var index: IndexPath! // a cell must not know its index path
    public var fieldModel: ComposeFieldModel?
    public var isExpanded = false
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none        
    }

    func setInitial(text: String) {
        textView.text = text
    }

    func setInitial(text: NSAttributedString) {
        textView.attributedText = text
    }

    public func updateCell(_ model: ComposeFieldModel, _ indexPath: IndexPath) {
        index = indexPath // a cell must not know it's index path
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
        cmTextview.addNewlinePadding()
        delegate?.textdidChange(at: index, textView: cmTextview)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        delegate?.textDidEndEditing(at: index, textView: cmTextview)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if fieldModel?.type == .subject && text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
