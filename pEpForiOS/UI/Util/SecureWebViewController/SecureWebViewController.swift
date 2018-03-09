//
//  WebViewNoJS.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit

class SecureWebViewController: UIViewController {
    static let storyboardId = "SecureWebViewController"
    private var webView: WKWebView!

    // MARK: - Life Cycle

    // Due to an Apple bug (https://bugs.webkit.org/show_bug.cgi?id=137160),
    // WKWebView has to be created programatically when supporting iOS versions < iOS11.
    // This implementation is taken over from the Apple docs:
    // https://developer.apple.com/documentation/webkit/wkwebview#2560973
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = false
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
    }

    // MARK: - API

    func display(htmlString: String) {
        webView.loadHTMLString(htmlString, baseURL: nil) //IOS-836: trick: wrong base url?
    }
}

extension SecureWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .other:
            // We are initially loading our own HTML
            decisionHandler(.allow)
            return
        case .linkActivated:
            // Open clicked links in external apps
            guard let newURL = navigationAction.request.url, UIApplication.shared.canOpenURL(newURL)
                else {
                    break

            }
            UIApplication.shared.openURL(newURL)
        case .backForward, .formResubmitted, .formSubmitted, .reload:
            // ignore
            break
        }
        decisionHandler(.cancel)
    }
}
