//
//  UIStackView+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 22/1/21.
//  Copyright © 2021 pEp Security SA. All rights reserved.
//

import UIKit

extension UIStackView {

    /// Remove the view passed by parameter from the stackview and from view hierarchy.
    /// - Parameter view: The view to rremove
    public func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    /// Remove all the arrangedSubviews from the stackview and from view hierarchy.
    public func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { (view) in
            removeFully(view: view)
        }
    }
}
