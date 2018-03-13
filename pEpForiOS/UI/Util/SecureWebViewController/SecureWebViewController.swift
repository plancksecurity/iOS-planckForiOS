//
//  WebViewNoJS.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit

protocol SecureWebViewControllerDelegate {
    func secureWebViewController(_ webViewController: SecureWebViewController, sizeChangedTo size: CGSize)
}

/// Webview that does not:
/// - excecute JS
/// - load any remote content
/// Note: It is insecure to use this class on iOS < 11. Thus it will intentionally take the
/// emergency exit and crash when trying to use it running iOS < 11.
class SecureWebViewController: UIViewController {
    static var isSaveToUseWebView: Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }
    static let storyboardId = "SecureWebViewController"
    private var webView: WKWebView!
    private var sizeChangeObserver: NSKeyValueObservation?
    private var _scrollingEnabled: Bool = true
    var scrollingEnabled: Bool {
        get {
            return _scrollingEnabled
        }
        set {
            _scrollingEnabled = newValue
            if let wv = webView {
                wv.scrollView.isScrollEnabled = _scrollingEnabled
            }
        }
    }
    var delegate: SecureWebViewControllerDelegate?

    // MARK: - Life Cycle

    var hasCompletelyLoadedAndSetup = false
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.scrollView.isScrollEnabled = scrollingEnabled

        let handler = { (scrollView: UIScrollView, change: NSKeyValueObservedChange<CGSize>) in
            if self.hasCompletelyLoadedAndSetup {
                return
            }
            if let contentSize = change.newValue {
                print("contentSize:", contentSize)
                if contentSize.width == 0.0 {
                    return
                }
                self.webView.frame.size = contentSize
                self.hasCompletelyLoadedAndSetup = true
                self.delegate?.secureWebViewController(self, sizeChangedTo: contentSize)

            }
        }
        sizeChangeObserver = webView.scrollView.observe(\UIScrollView.contentSize,
                                                        options: [NSKeyValueObservingOptions.new],
                                                        changeHandler: handler)
    }

    // Due to an Apple bug (https://bugs.webkit.org/show_bug.cgi?id=137160),
    // WKWebView has to be created programatically when supporting iOS versions < iOS11.
    // This implementation is taken over from the Apple docs:
    // https://developer.apple.com/documentation/webkit/wkwebview#2560973
    override func loadView() {
        guard #available(iOS 11.0, *) else {
            // WKContentRuleList is not available below iOS11, thus remote content would be loaded
            // which is considered as inaceptable for a secure web view.
            // Emergency exit.
            fatalError()
        }
        let config = WKWebViewConfiguration()
        let prefs = WKPreferences()
        //IOS-836: add rule list
        prefs.javaScriptEnabled = false
        config.preferences = prefs
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = scrollingEnabled
        view = webView
    }

    // MARK: - API

    func display(htmlString: String) {
        webView.loadHTMLString(htmlString, baseURL: nil) //IOS-836: trick: wrong base url?
    }
}

// MARK: - WKNavigationDelegate

extension SecureWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
