//
//  UIPopoverPresentationControllerProtocol.swift
//  pEp
//
//  Created by Martín Brude on 12/11/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation


protocol UIPopoverPresentationControllerProtocol {
   func repositionPopoverTo(rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>)
}

extension UIPopoverPresentationControllerProtocol where Self: UIViewController {
   func repositionPopoverTo(rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
       guard let titleView = navigationItem.titleView else {
           return
       }

       let newRect = CGRect(x:titleView.bounds.midY, y: titleView.bounds.midX, width:0, height:0)
       rect.initialize(to: newRect)
       view.pointee = titleView
   }
}
