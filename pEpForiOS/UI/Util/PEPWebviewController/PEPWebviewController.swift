//
//  PEPWebviewController.swift
//  pEp
//
//  Created by Martin Brude on 03/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import WebKit

import pEpIOSToolbox

class PEPWebViewController: UIViewController {

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    var urlClickHandler: SecureWebViewUrlClickHandlerProtocol?
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        showNavigationBar()
        urlClickHandler = UrlClickHandler()
    }

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = false
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
    }
}

// MARK: - WKNavigationDelegate
extension PEPWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .other:
            // We are initially loading our own HTML
            decisionHandler(.allow)
            return
        case .linkActivated:
            // Open clicked links in Safari
            guard let newURL = navigationAction.request.url else {
                break
            }
            if newURL.scheme == "mailto" {
                // The user clicked on an email URL.
                urlClickHandler?.didClickOn(mailToUrlLink: newURL)
            } else if UIApplication.shared.canOpenURL(newURL) {
                UIApplication.shared.open(newURL, options: [:])
            }
        case .backForward, .formResubmitted, .formSubmitted, .reload:
            break
        @unknown default:
            Log.shared.errorAndCrash("Unhandled case")
        }
        decisionHandler(.cancel)
    }
}
