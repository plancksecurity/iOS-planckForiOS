//
//  EmailViewController+UIPopoverPresentationControllerDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 31/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension EmailViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect:
        UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {

        guard let titleView = navigationItem.titleView else {
            return
        }

        rect.initialize(to: CGRect(x:titleView.bounds.midY,
                                   y: titleView.bounds.midX,
                                   width:0,
                                   height:0))
        view.pointee = titleView

    }
}

