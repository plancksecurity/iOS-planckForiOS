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
    enum Scheme: String {
        case mailto = "mailto"

        init?(for url: URL) {
            guard let schemeStr = url.scheme, let scheme = Scheme(rawValue: schemeStr) else {
                return nil
            }
            self = scheme
        }
    }
    /// View controller to act on.
    private var actor: UIViewController
    private let appConfig: AppConfig

    required init(actor: UIViewController, appConfig: AppConfig) {
        self.actor = actor
        self.appConfig = appConfig
    }

    private func presentComposeView(forRecipientInUrl url: URL) {
        UIUtils.presentComposeView(forRecipientInUrl: url, on: actor, appConfig: appConfig)
    }

    private func presentAvailableMailtoUrlHandlingChoices(for url: URL, at view: UIView) {
        UIUtils.presentActionSheetWithContactOptions(forUrl: url,
                                                     on: actor,
                                                     at: view,
                                                     appConfig: appConfig)
    }

    // MARK: - UITextViewDelegate

    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange) -> Bool {
        if URL.scheme == "mailto" {
            presentComposeView(forRecipientInUrl: URL)
            return false
        }
        return true
    }

    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard let scheme = Scheme(for: URL) else {
            // We have no custom handling for this URL type.
             return true
        }
        if scheme == .mailto && interaction == .presentActions  {
            // User long-pressed on mailto url
            presentAvailableMailtoUrlHandlingChoices(for: URL, at: textView)
            return false
        } else if scheme == .mailto && interaction == .invokeDefaultAction {
            // User clicked on mailto url
            presentComposeView(forRecipientInUrl: URL)
            return false
        }
        return true
    }

    // MARK: - SecureWebViewUrlClickHandlerProtocol

    func secureWebViewController(_ webViewController: SecureWebViewController,
                                 didClickMailToUrlLink url: URL) {
        presentComposeView(forRecipientInUrl: url)
    }
}
