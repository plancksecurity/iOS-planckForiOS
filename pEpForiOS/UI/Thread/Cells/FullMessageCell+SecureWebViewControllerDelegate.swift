//Message threading related code. Commented out as this feature does not exist and needs rewrite.
// Keep this code, it might be reusable when reimplementing message threading

////
////  FullMessageCell+SecureWebViewControllerDelegate.swift
////  pEp
////
////  Created by Borja González de Pablo on 22/06/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//
//extension FullMessageCell: SecureWebViewControllerDelegate {
//    func secureWebViewController(_ webViewController: SecureWebViewController, sizeChangedTo size: CGSize) {
//        self.contentHeightConstraint.constant = size.height
//        self.contentHeightConstraint.isActive = true
//        requestsReload?()
//    }
//}
