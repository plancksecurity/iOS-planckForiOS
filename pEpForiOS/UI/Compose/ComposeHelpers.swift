//
//  ComposeHelpers.swift
//  pEpForiOS
//
//  Created by Yves Landert on 04.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

let defaultCellHeight: CGFloat = 64.0

extension UITableView {
    
    public final func updateSize(_ animated: Bool = false) {
        UIView.setAnimationsEnabled(animated)
        beginUpdates()
        endUpdates()
        UIView.setAnimationsEnabled(animated)
    }

    public final func scrollToTopOf(_ cell: UITableViewCell) {
        var center = contentOffset
        center.y = cell.frame.origin.y - defaultCellHeight
        contentOffset = center
    }
}

extension String {
    
    static var TextAttachmentCharacter: UInt64 {
        return 4799450059485662934 // 0xfffc // hash: 197367
    }
    
    var cleanAttachments: String {
        for ch in self.characters {
            if UInt64(ch.hashValue) == String.TextAttachmentCharacter {
                return self.replacingOccurrences(of: String(ch), with: "").trim
            }
        }
        return self
    }
    
    var isAttachment: Bool {
        if self.isEmpty { return false }
        if UInt64(self.hashValue) == String.TextAttachmentCharacter {
            return true
        }
        return false
    }
}

extension UIImage {
    
    public final func attachment(_ text: String, textColor: UIColor = .gray) -> UIImage {
        let attributes = [
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12.0)
        ]
        
        let textMargin: CGFloat = 3.0
        let textSize = text.size(attributes: attributes)
        var textFrame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
        var imageSize = size
        let iconWidth = imageSize.width
        var imagePosX: CGFloat = 0.0
        var textPosX = (iconWidth - textSize.width) / 2
        
        if textSize.width > imageSize.width {
            imageSize.width = textSize.width
            imagePosX = (textSize.width - iconWidth) / 2
            textPosX = 0.0
        }
        
        textFrame.origin = CGPoint(x: textPosX, y: imageSize.height + textMargin)
        imageSize.height = imageSize.height + textSize.height + textMargin
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        draw(in: CGRect(x: imagePosX, y: 0, width: iconWidth, height: imageSize.height - textSize.height - textMargin))
        text.draw(in: textFrame, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    public final func recepient(_ text: String, textColor: UIColor = .black) -> UIImage {
        let attributes = [
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName: UIFont.pEpInput
        ]
        
        let textMargin: CGFloat = 4.0
        let textSize = text.size(attributes: attributes)
        var textFrame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
        
        var imageSize = size
        let textPosX = imageSize.width + textMargin
        let imageWidth = imageSize.width + textFrame.width + (textMargin * 2)
        
        textFrame.origin = CGPoint(x: textPosX, y: ((imageSize.height - textFrame.size.height) / 2))
        imageSize.width = imageWidth
        imageSize.height = size.height + 2.0
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        text.draw(in: textFrame, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}

// MARK: - Compose Helper Class

open class ComposeHelper {
    
    // Builds a pEp mail dictionary from all the related views. This is just a quick
    // method for checking the pEp color rating, it's not exhaustive!
    
//    open static func pepMailFromViewForCheckingRating(_ vc: ComposeTableViewController) -> PEPMessage? {
//        var message = PEPMessage()
//        
//        for (_, cell) in vc.recipientCells {
//            let tf = cell.textView
//            if let text = tf?.text {
//                let mailStrings0 = text.removeLeadingPattern(vc.leadingPattern)
//                if !mailStrings0.isOnlyWhiteSpace() {
//                    let mailStrings1 = mailStrings0.components(
//                        separatedBy: vc.recipientStringDelimiter).map() {
//                            $0.trimmedWhiteSpace()
//                    }
//                    
//                    let mailStrings2 = mailStrings1.filter() {
//                        !$0.isOnlyWhiteSpace()
//                    }
//                    let contacts: [PEPIdentity] = mailStrings2.map() {
//                        if let c = Identity.by(address: $0) {
//                            return PEPUtil.pEp(identity: c)
//                        }
//                        return PEPUtil.pEpIdentity(email: $0, name: $0.namePartOfEmail())
//                    }
//                    if contacts.count > 0 {
//                        if let rt = cell.fieldModel?.type {
//                            var pepKey: String? = nil
//                            switch rt {
//                            case .to:
//                                pepKey = kPepTo
//                            case .cc:
//                                pepKey = kPepCC
//                            case .bcc:
//                                pepKey = kPepBCC
//                            default: ()
//                                break
//                            }
//                            if let key = pepKey {
//                                message[key] = NSArray(array: contacts)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        guard let account = vc.appConfig?.currentAccount else {
//            Log.warn(component: vc.comp, "Need valid account for determining pEp rating")
//            return nil
//        }
//        message[kPepFrom] = PEPUtil.pEp(identity: account.user) as AnyObject?
//        
//        if let subjectText = vc.subjectTextField?.text {
//            message[kPepShortMessage] = subjectText as AnyObject?
//        }
//        if let bodyText = vc.longBodyMessageTextView?.text {
//            message[kPepLongMessage] = bodyText as AnyObject?
//        }
//        message[kPepOutgoing] = NSNumber(booleanLiteral: true)
//        return message
//    }
}

