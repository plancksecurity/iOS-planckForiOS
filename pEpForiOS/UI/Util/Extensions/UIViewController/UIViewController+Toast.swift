//
//  UIViewController+Toast.swift
//  pEpForiOS
//
//  Created by Martín Brude on 19/1/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {

    func showToast(message : String) {
        let font = UIFont.pepFont(style: .body, weight: .regular)
        let maxWidth = view.frame.size.width - 40
        let width = message.width(withConstrainedHeight: 100, font: font)
        let height = message.height(withConstrainedWidth: maxWidth, font: font)
        let screenSize: CGRect = UIScreen.main.bounds
        let finalWidth = min(maxWidth, width) + 8
        let finalHeight = min(height, 100) + 4
        let frame = CGRect(x: view.frame.size.width / 2 - finalWidth/2, y: screenSize.height * 0.75, width: finalWidth, height: finalHeight)
        let toastLabel = UILabel(frame: frame)
        toastLabel.backgroundColor = .systemBackground.withAlphaComponent(0.6)
        toastLabel.textColor = .label
        toastLabel.font = UIFont.pepFont(style: .body, weight: .regular)
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { (isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

