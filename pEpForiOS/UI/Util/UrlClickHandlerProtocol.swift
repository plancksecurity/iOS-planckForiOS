//
//  UrlClickHandlerProtocol.swift
//  pEp
//
//  Created by Andreas Buff on 02.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/// If pEp offers custom handling for a URL clicked by a user, here is the place for the custom
/// implementation.
/// Note: Conforming classes have to inherit from NSObject. Conforming to UITextViewDelegate
/// requires that for some reason.
protocol UrlClickHandlerProtocol: SecureWebViewUrlClickHandlerProtocol, UITextViewDelegate {
    /// View Controller to act on.
    var actor: UIViewController? { get }
    /// - Parameter actor: View Controller to act on.
    init(actor: UIViewController)
}

//IOS-1222: move!
class UrlClickHandler: NSObject, UrlClickHandlerProtocol {
    /// View controller to act on.
    var actor: UIViewController?

    required init(actor: UIViewController) {
        self.actor = actor
    }

    // MARK: - UITextViewDelegate

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.scheme == "mailto" {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "IOS-1222 unimplemented stub")
            return false
        }
        return true
    }

    // MARK: - SecureWebViewUrlClickHandlerProtocol

    func secureWebViewController(_ webViewController: SecureWebViewController, didClickMailToUrlLink url: URL) {
         Log.shared.errorAndCrash(component: #function, errorString: "IOS-1222 unimplemented stub")
    }
}
