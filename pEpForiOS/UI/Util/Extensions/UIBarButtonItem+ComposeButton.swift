//
//  UIBarButtonItem+ComposeButton.swift
//  pEp
//
//  Created by Adam Kowalski on 05/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIBarButtonItem {

    public static func getComposeButton(tapAction: Selector, longPressAction: Selector, target: Any) -> UIBarButtonItem {
        let tapGesture = UITapGestureRecognizer(target: target, action: tapAction)
        let longGesture = UILongPressGestureRecognizer(target: target, action: longPressAction)
        longGesture.allowableMovement = 1
        longGesture.minimumPressDuration = 0.8
        longGesture.numberOfTapsRequired = 0
        // Custom view
        let viewContainerForComposeButton = UIView(frame: CGRect(x: 0, y: 0, width: 22, height: 30))
        let composeImage = #imageLiteral(resourceName: "compose")
        let composeImageButton = UIImageView(image: composeImage)
        composeImageButton.tintColor = .white
        composeImageButton.sizeThatFits(viewContainerForComposeButton.frame.size)
        viewContainerForComposeButton.addSubview(composeImageButton)

        viewContainerForComposeButton.addGestureRecognizer(tapGesture)
        viewContainerForComposeButton.addGestureRecognizer(longGesture)
        let compose = UIBarButtonItem(customView: viewContainerForComposeButton)
        compose.tintColor = .white
        return compose
    }
}
