//
//  LoginScrollView.swift
//  pEp
//
//  Created by Alejandro Gelos on 21/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

@IBDesignable
class LoginScrollView: UIScrollView {
    @IBInspectable var makeVisibleAutoScroll: Bool = true

    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        guard makeVisibleAutoScroll else { return }
        super.scrollRectToVisible(rect, animated: animated)
    }
}
