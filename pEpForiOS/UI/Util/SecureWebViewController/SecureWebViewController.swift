//
//  WebViewNoJS.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit

protocol SecureWebViewControllerDelegate {
    /// Called after the webview has finished loadding and layouting its subviews.
    /// - Parameters:
    ///   - webViewController: calling view controller
    ///   - size: webview.scrollview.contentSize after loading html content and layouting
    func secureWebViewController(_ webViewController: SecureWebViewController, sizeChangedTo size: CGSize)
}

/// Webview that does not:
/// - excecute JS
/// - load any remote content
/// Note: It is insecure to use this class on iOS < 11. Thus it will intentionally take the
/// emergency exit and crash when trying to use it running iOS < 11.
class SecureWebViewController: UIViewController {
    private var webView: WKWebView!
    private var sizeChangeObserver: NSKeyValueObservation?

    static var isSaveToUseWebView: Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }
    static let storyboardId = "SecureWebViewController"
    /// webview.scrollView.contentSize after html has finished loading and layouting
    private(set) var contentSize: CGSize?

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
        informDelegateAfterLoadingFinished()
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
        if webView != nil {
            return
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
        //IOS-836: we need to get access to inlined attachments (WKURLSchemeHandler)
    }

    // MARK: - WKURLSchemeHandler (load local resources)

    private func setupSchemeHandler() {
        let inlinedImagesScheme = "security.pep.SecureWebViewController.setupSchemeHandler"
    }

    // MARK: - WKContentRuleList (block loading of all remote content)

    private func setupBlocklist(completion: @escaping () -> Void) {
        guard #available(iOS 11.0, *) else {
            return
        }

        let listID = "pep.security.SecureWebViewController.block_all_external_content"
        var compiledBlockList: WKContentRuleList?

        // Function to set the compiled block list
        let setBlocklist = {
            if compiledBlockList != nil {
                DispatchQueue.main.async {
                    let configuration = self.webView.configuration
                    configuration.userContentController.add(compiledBlockList!)
                    completion()
                }
            }
        }

        let loadGroup = DispatchGroup()
        loadGroup.enter()

        WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: listID) {
            (loadedRuleList, error) in
            if let error = error {
                Log.shared.errorAndCrash(component: #function, errorString: "Problem: \(error)")
                return
            }
            compiledBlockList = loadedRuleList
            loadGroup.leave()
        }
        loadGroup.notify(queue: DispatchQueue.main) {
            if compiledBlockList != nil {
                // We have it, set it.
                setBlocklist()
                return
            }

            // No previous blocklist exists. Compile a new one.
            let blockRules = self.blockRulesJson

            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "pep.security.SecureWebViewController.block_all_external_content",
                encodedContentRuleList: blockRules) { (contentRuleList, error) in
                    if let error = error {
                        Log.shared.errorAndCrash(component: #function,
                                                 errorString: "Compile error: \(error)")
                        return
                    }
                    compiledBlockList = contentRuleList
                    guard let _ = compiledBlockList else {
                        Log.shared.errorAndCrash(component: #function,
                                                 errorString:
                            "Emergency exit. External content not blocked.")
                        completion()
                        return

                    }
                    // We have it, set it.
                    setBlocklist()
            }
        }
    }

    // Type is Any as WKContentRuleList is available in iOS>=11
    private var blockRulesJson: String {
        // This rule blocks all content.
        //IOS-836: add exception for inbedded images
        return """
         [{
             "trigger": {
                 "url-filter": ".*"
             },
             "action": {
                 "type": "block"
             }
        },
        {
            "trigger": {
                "url-filter": ".cid*"
        },
            "action": {
                "type": "ignore-previous-rules"
        }
        }]
      """
    }
    //IOS-836: double check if cid is required, i.e. how block rules play together with WKURLSchemeHandler

    // MARK: - Handle Content Size Changes

    private func informDelegateAfterLoadingFinished() {
        // code to run whenever the content(size) changes
        let handler = { (scrollView: UIScrollView, change: NSKeyValueObservedChange<CGSize>) in
            guard
                let contentSize = change.newValue,
                !self.shouldIgnoreContentSizeChange(newSize: contentSize) else {
                    return
            }
            self.contentSize = contentSize
            self.delegate?.secureWebViewController(self, sizeChangedTo: contentSize)
        }
        sizeChangeObserver = webView.scrollView.observe(\UIScrollView.contentSize,
                                                        options: [NSKeyValueObservingOptions.new],
                                                        changeHandler: handler)
    }

    // We ignore calls before html content has been loaded (zero size).
    // Also we do not want to bother the delegate if the size did not change (to
    // improve performance and to avoid endless loops inform delegate -> delegate
    // triggers layout of subviews -> contentSize is set but did not change ->
    // inform delegate ...)
    ///
    /// - Parameter newSize: new contentSize to figure out whether or not to ignore the change for
    /// - Returns:  true: if we should not trigger any actions for the change in content size
    ///             false: otherwize
    private func shouldIgnoreContentSizeChange(newSize: CGSize) -> Bool {
        return newSize.width == 0.0 || newSize == self.contentSize
    }

    /// Returns a modified version the html, adjusted to simulate "PageScaleToFit" layout by
    /// inserting "<meta name="viewport" content="width=device-width, initial-scale=1.0"/>".
    private func dirtyHackInsertedForPageScaleToFit(inHtml html: String) -> String {
        var result = html
        if html.contains(find: "initial-scale=1.0") {
            // scale factor already set. Nothing to do.
            return result
        }

        if html.contains(find: "<head>") {
            result = html.replacingOccurrences(of: "<head>", with:
                """
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        """)
        } else if html.contains(find: "<html>") {
            result = html.replacingOccurrences(of: "<html>", with:
                """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        </head>
        """
            )
        }
        return result
    }

    // MARK: - API

    func display(htmlString: String) {
        let scaledHtml = dirtyHackInsertedForPageScaleToFit(inHtml: htmlString)
        setupBlocklist() {
            self.webView.loadHTMLString(scaledHtml, baseURL: nil) //IOS-836: trick: wrong base url?
        }
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

// MARK: - WKURLSchemeHandler

@available(iOS, introduced: 11.0)
/// WKURLSchemeHandler subclass to handle cid: URLs (images inlined in mails).
/// Provides content from MessageModel for a certain content ID.
class SchemeHandlerCid : NSObject, WKURLSchemeHandler {

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {

    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

    }
}
