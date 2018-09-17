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
let defaultFilenameLength = 20

extension String {
    static let textAttachmentCharacter: UInt32 = 65532

    var cleanAttachments: String {
        if let uc = UnicodeScalar(String.textAttachmentCharacter) {
            let s = String(Character(uc))
            return self.replacingOccurrences(of: s, with: "").trimmed()
        }
        return self
    }

    var isAttachment: Bool {
        guard self.count == 1 else {
            return false
        }
        if let ch = self.unicodeScalars.first {
            return ch.value == String.textAttachmentCharacter
        }
        return false
    }
    
    var truncate: String {
        let length = self.count
        if length > defaultFilenameLength {
            let index: String.Index = self.index(self.startIndex, offsetBy: defaultFilenameLength)
            return String(prefix(upTo: index))
        }
        return self
    }
}

extension UIImage {
    public final func attachment(_ text: String, textColor: UIColor = .gray) -> UIImage {
        let attributes = [
            NSAttributedStringKey.foregroundColor: textColor,
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 12.0)
        ]
        
        let textMargin: CGFloat = 3.0
        let textSize = text.size(withAttributes: attributes)
        var textFrame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
        var imageSize = size
        let iconWidth = imageSize.width
        var imagePosX: CGFloat = 0.0
        var textPosX = round((iconWidth - textSize.width) / 2)
        
        if textSize.width > imageSize.width {
            imageSize.width = textSize.width
            imagePosX = round((textSize.width - iconWidth) / 2)
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
}

// MARK: - Compose Helper Class

open class ComposeHelper {
    public static func recepient(_ text: String, textColor: UIColor = .pEpGreen, maxWidth: CGFloat = 0.0) -> UIImage {
        let attributes = [
            NSAttributedStringKey.foregroundColor: textColor,
            NSAttributedStringKey.font: UIFont.pEpInput
        ]
        
        let textMargin: CGFloat = 4.0
        let textSize = text.size(withAttributes: attributes)
        var width = textSize.width
        if width > maxWidth {
            width = maxWidth
        }
        var textFrame = CGRect(x: 0, y: 0, width: width, height: textSize.height)

        let label = UILabel()
        label.text = "Hello"
        label.sizeToFit()

        var imageSize = label.bounds.size
        imageSize.width = 0
        let textPosX = imageSize.width + textMargin
        let imageWidth = imageSize.width + textFrame.width + (textMargin * 2)

        textFrame.origin = CGPoint(x: textPosX,
                                   y: round((imageSize.height - textFrame.size.height) / 2))
        imageSize.width = imageWidth
        imageSize.height += 2.0

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)

        text.draw(with: textFrame, options: [
            NSStringDrawingOptions.truncatesLastVisibleLine,
            NSStringDrawingOptions.usesLineFragmentOrigin
            ], attributes: attributes, context: nil)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
}

