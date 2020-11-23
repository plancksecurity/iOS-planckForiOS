//
//  UITextView+Font.swift
//  pEpIOSToolbox
//
//  Created by Adam Kowalski on 13/02/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import UIKit

extension UITextView {
    /// Sets pEp default custom font with respecting TextStyle - Dynamic Fonts
    @available(iOS 11, *)
    public func pEpSetFontFace(weight: UIFont.Weight = .regular) {
        guard let fontFace = font,
            let textStyle = fontFace.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.textStyle) as? String else {
                Log.shared.error("Missing UIFont.TextStyle")
                return
        }

        font = UIFont.pepFont(style: UIFont.TextStyle.init(rawValue: textStyle), weight: weight)
    }
}
