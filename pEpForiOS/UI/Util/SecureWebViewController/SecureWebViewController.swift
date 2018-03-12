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

class SecureWebViewController: UIViewController {
    static let storyboardId = "SecureWebViewController"
    private var webView: WKWebView!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.scrollView.isScrollEnabled = scrollingEnabled
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
        let webConfiguration = WKWebViewConfiguration()
        let prefs = WKPreferences()
        //IOS-836: add rule list
        prefs.javaScriptEnabled = false
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = scrollingEnabled
        view = webView
    }

    // MARK: - API

    func display(htmlString: String) {
        webView.loadHTMLString(htmlString, baseURL: nil) //IOS-836: trick: wrong base url?
    }
}

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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight") { (response, error) in
            guard let value = response as? Float else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Cast error")
                    return
            }
            var frame = webView.frame
            let height = CGFloat(value)
            frame.size.height = height
            webView.frame = frame
            self.delegate?.secureWebViewController(self, sizeChangedTo: frame.size)
        }
    }
}
