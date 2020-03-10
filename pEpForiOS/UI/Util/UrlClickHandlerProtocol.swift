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
    private weak var actor: UIViewController?
    private let appConfig: AppConfig

    required init(actor: UIViewController, appConfig: AppConfig) {
        self.actor = actor
        self.appConfig = appConfig
    }

    private func presentComposeView(forRecipientInUrl url: URL) {
        if let theActor = actor {
            UIUtils.presentComposeView(forRecipientInUrl: url, on: theActor, appConfig: appConfig)
        }
    }

    private func presentAvailableMailtoUrlHandlingChoices(for url: URL, at rect: CGRect, at view: UIView) {
        if let theActor = actor {
            UIUtils.presentActionSheetWithContactOptions(forUrl: url,
                                                         on: theActor,
                                                         at: rect,
                                                         at: view,
                                                         appConfig: appConfig)
        }
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

    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard let scheme = Scheme(for: URL) else {
            // We have no custom handling for this URL type.
             return true
        }
        if scheme == .mailto && interaction == .presentActions  {
            // User long-pressed on mailto url
            let urlRect = getUrlRect(textView: textView, in: characterRange)
            presentAvailableMailtoUrlHandlingChoices(for: URL, at: urlRect, at: textView)
            return false
        } else if scheme == .mailto && interaction == .invokeDefaultAction {
            // User clicked on mailto url
            presentComposeView(forRecipientInUrl: URL)
            return false
        }
        return true
    }

    private func getUrlRect(textView: UITextView,
                            in characterRange: NSRange) -> CGRect {
        let begining = textView.beginningOfDocument
        let start = textView.position(from: begining, offset: characterRange.location)!
        let end = textView.position(from: start, offset: characterRange.length)!
        let range = textView.textRange(from: start, to: end)!
        return textView.firstRect(for:range)
    }

    // MARK: - SecureWebViewUrlClickHandlerProtocol

    func secureWebViewController(_ webViewController: SecureWebViewController,
                                 didClickMailToUrlLink url: URL) {
        presentComposeView(forRecipientInUrl: url)
    }
}
extension UITextInput {
    var selectedRange: NSRange? {
        guard let range = self.selectedTextRange else {
            return nil

        }
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = offset(from: range.start, to: range.end)
        return NSRange(location: location, length: length)
    }
}
