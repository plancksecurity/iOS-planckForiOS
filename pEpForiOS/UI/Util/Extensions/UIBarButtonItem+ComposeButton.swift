//
//  UIBarButtonItem+ComposeButton.swift
//  pEp
//
//  Created by Adam Kowalski on 05/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIBarButtonItem {


    /// Compose button
    /// - Parameters:
    ///   - tapAction: Required selector for tap gesture recognizer
    ///   - longPressAction: Optional selector for long press gesture recognizer
    ///   - target: target for recognizers
    /// - Returns: compose button with icon and connected events
    public static func getComposeButton(tapAction: Selector,
                                        longPressAction: Selector? = nil,
                                        target: Any) -> UIBarButtonItem {

        // Custom view
        let viewContainerForComposeButton = UIView(frame: CGRect(x: 0, y: 0, width: 22, height: 30))
        let composeImage = #imageLiteral(resourceName: "compose")
        let composeImageButton = UIImageView(image: composeImage)
        composeImageButton.tintColor = .white
        composeImageButton.sizeThatFits(viewContainerForComposeButton.frame.size)
        viewContainerForComposeButton.addSubview(composeImageButton)

        let tapGesture = UITapGestureRecognizer(target: target, action: tapAction)
        viewContainerForComposeButton.addGestureRecognizer(tapGesture)
        if let longPressAction = longPressAction {
            let longGesture = UILongPressGestureRecognizer(target: target, action: longPressAction)
            longGesture.allowableMovement = 1
            longGesture.minimumPressDuration = 0.8
            longGesture.numberOfTapsRequired = 0
            viewContainerForComposeButton.addGestureRecognizer(longGesture)
        }
        let compose = UIBarButtonItem(customView: viewContainerForComposeButton)
        compose.tintColor = .white
        return compose
    }
}
