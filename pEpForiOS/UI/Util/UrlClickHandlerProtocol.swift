//
//  UrlClickHandlerProtocol.swift
//  pEp
//
//  Created by Andreas Buff on 02.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// If pEp offers custom handling for a URL clicked by a user, here is the place for the custom
/// implementation.
/// Note: Conforming classes have to inherit from NSObject. Conforming to UITextViewDelegate
/// requires that for some reason.
protocol UrlClickHandlerProtocol: SecureWebViewUrlClickHandlerProtocol, UITextViewDelegate {
    /// - Parameters:
    ///   - actor: View Controller to act on
    ///   - appConfig: appConfig. Required to pass around
    init(actor: UIViewController, appConfig: AppConfig)
}

class UrlClickHandler: NSObject, UrlClickHandlerProtocol {
    /// View controller to act on.
    var actor: UIViewController
    let appConfig: AppConfig

    required init(actor: UIViewController, appConfig: AppConfig) {
        self.actor = actor
        self.appConfig = appConfig
    }

    private func presentComposeView(forRecipientInUrl url: URL) {
        let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
        guard
            let address = url.firstRecipientAddress(),
            let composeNavigationController = storyboard.instantiateViewController(withIdentifier: Constants.composeSceneStoryboardId) as? UINavigationController,
            let composeVc = composeNavigationController.rootViewController as? ComposeTableViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Missing required data")
                return
        }
        composeVc.appConfig = appConfig
        composeVc.composeMode = .replyFrom
        let to = Identity(address: address)
        composeVc.prefilledTo = to
        actor.present(composeNavigationController, animated: true)
    }

    // MARK: - UITextViewDelegate

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.scheme == "mailto" {
            presentComposeView(forRecipientInUrl: URL)
            return false
        }
        return true
    }

    // MARK: - SecureWebViewUrlClickHandlerProtocol

    func secureWebViewController(_ webViewController: SecureWebViewController, didClickMailToUrlLink url: URL) {
        presentComposeView(forRecipientInUrl: url)
    }
}
