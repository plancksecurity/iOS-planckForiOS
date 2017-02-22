//
//  ComposeTextView.swift
//
//  Created by Igor Vojinovic on 11/4/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel


open class ComposeTextView: UITextView {

    public var fieldModel: ComposeFieldModel?
    
    fileprivate final var fontDescender: CGFloat = -7.0
    fileprivate final var textBottomMargin: CGFloat = 25.0
    fileprivate final var imageFieldHeight: CGFloat = 66.0
    
    public final var fieldHeight: CGFloat {
        get {
            let size = sizeThatFits(CGSize(width: frame.size.width, height: CGFloat(FLT_MAX)))
            return size.height + textBottomMargin
        }
    }
    
    public final func scrollToBottom() {
        if fieldHeight >= imageFieldHeight {
            setContentOffset(CGPoint(x: 0.0, y: fieldHeight - imageFieldHeight), animated: true)
        }
    }
    
    public final func scrollToTop() {
        contentOffset = .zero
    }
        
    public final func insertImage(_ identity: Identity, _ hasName: Bool = false) {
        let attrText = NSMutableAttributedString(attributedString: attributedText)
        
        var string = identity.address.trim
        var scheme: (color: UIColor, image: UIImage?)
        if !hasName {
           scheme = (.pEpNoColor, UIImage().noColorImage(string))
        } else {
            if let username = identity.userName {
                string = username
            }
            scheme = identity.pEpScheme
            if scheme.image == nil {
               scheme = (.pEpNoColor, UIImage().noColorImage(string))
            }
        }
        
        let img = scheme.image?.recepient(string, textColor: scheme.color)
        let at = TextAttachment()
        at.image = img
        at.bounds = CGRect(x: 0, y: fontDescender, width: img!.size.width, height: img!.size.height)
        
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        attrText.addAttribute(NSFontAttributeName,
            value: UIFont.pEpInput,
            range: NSRange(location: 0, length: attrText.length)
        )
        attributedText = attrText
    }
    
    public final func textAttachments() -> [TextAttachment?] {
        var allAttachments = [TextAttachment?]()
        let range = NSMakeRange(0, attributedText.length)
        if range.length > 0 {
            attributedText.enumerateAttribute(NSAttachmentAttributeName, in: range,
                options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
                if value != nil {
                    let attachment = value as! TextAttachment
                    allAttachments.append(attachment)
                }
            }
        }
        
        return allAttachments
    }
    
    public final func getAttachments(_ string: String) -> [TextAttachment?] {
        var allAttachments = [TextAttachment?]()
        let range = NSMakeRange(0, string.characters.count)
        if range.length > 0 {
            attributedText.enumerateAttribute(NSAttachmentAttributeName, in: range,
                options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
                if value != nil {
                    let attachment = value as! TextAttachment
                    allAttachments.append(attachment)
                }
            }
        }
        
        return allAttachments
    }
    
    public final func removePlainText() {
        let attachments = textAttachments()
        if attachments.count > 0  {
            let new = NSMutableAttributedString()
            for at in attachments {
                let attachString = NSAttributedString(attachment: at!)
                new.append(attachString)
            }
            
            new.addAttribute(NSFontAttributeName,
                value: UIFont.pEpInput,
                range: NSRange(location: 0, length: new.length)
            )
            attributedText = new
        }
    }
    
    public final func removeAttachments() {
        let mutAttrString = NSMutableAttributedString(attributedString: attributedText)
        let range = NSMakeRange(0, mutAttrString.length)
        
        mutAttrString.enumerateAttributes(in: range, options: .reverse) { (attributes, theRange, stop) -> Void in
            for attachment in attributes {
                if attachment.value is NSTextAttachment {
                    mutAttrString.removeAttribute(attachment.0, range: theRange)
                }
            }
        }
    }
    
    public func toHtml() -> String? {
        let string = NSMutableAttributedString(attributedString: attributedText)
        let range = NSMakeRange(0, string.length)
        string.fixAttributes(in: range)
        
        let docAttributes = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]
        do {
            let data = try string.data(from: range, documentAttributes: docAttributes)
            return String(data: data, encoding: .utf8)
        } catch {
            Log.error(component: #function, errorString: "Could not covert into html")
            return nil
        }
    }
}
