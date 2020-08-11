//
//  WebViewNoJS.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit
import pEpIOSToolbox

protocol SecureWebViewControllerDelegate: class {
    /// Called on content size changes when content is loaded.
    func didFinishLoading()
}

protocol SecureWebViewUrlClickHandlerProtocol: class {
    /// Called whenever a mailto:// URL has been clicked by the user.
    /// - Parameter url: The mailto:// URL
    func didClickOn(mailToUrlLink url: URL)
}

// WKContentRuleList is not available below iOS11, thus remote content would be loaded
// which is considered as inaceptable for a secure web view.
@available(iOS 11.0, *)
/// Webview that does not:
/// - excecute JS
/// - load any remote content
/// Note: It is insecure to use this class on iOS < 11. Thus it will intentionally take the
/// emergency exit and crash when trying to use it running iOS < 11.
class SecureWebViewController: UIViewController {
    static public let storyboardId = "SecureWebViewController"

    public var contentSize: CGSize {
        get {
            return webView?.scrollView.contentSize ?? CGSize.zero
        }
    }

    private var _scrollingEnabled = false
    private var scrollingEnabled: Bool {
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

    private var _userInteractionEnabled = true
    private var userInteractionEnabled: Bool {
        get {
            return _userInteractionEnabled
        }
        set {
            _userInteractionEnabled = newValue
            if let wv = webView {
                wv.scrollView.isUserInteractionEnabled = _userInteractionEnabled
            }
        }
    }

    weak public var delegate: SecureWebViewControllerDelegate?
    weak public var urlClickHandler: SecureWebViewUrlClickHandlerProtocol?
    public var minimumFontSize: CGFloat = 16.0
    public var zoomingEnabled: Bool = true
    private var webView: WKWebView!
    private var htmlOptimizer = HtmlOptimizerUtil(minimumFontSize: 16.0)

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        htmlOptimizer = HtmlOptimizerUtil(minimumFontSize: minimumFontSize)
        webView.scrollView.isScrollEnabled = scrollingEnabled
    }

    // Due to an Apple bug (https://bugs.webkit.org/show_bug.cgi?id=137160),
    // WKWebView has to be created programatically when supporting iOS versions < iOS11.
    // This implementation is taken over from the Apple docs:
    // https://developer.apple.com/documentation/webkit/wkwebview#2560973
    override func loadView() {
        let config = WKWebViewConfiguration()

        config.preferences = preferences()
        config.dataDetectorTypes = [.link,
                                    .address,
                                    .calendarEvent,
                                    .phoneNumber,
                                    .trackingNumber,
                                    .flightNumber]
        // This handler provides local content for cid: URLs
        CidHandler.setup(config: config)
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.isScrollEnabled = scrollingEnabled
        webView.scrollView.isUserInteractionEnabled = userInteractionEnabled
        view = webView
    }

    // MARK: - API

    public func display(html: String) {
        setupBlocklist() { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.htmlOptimizer.optimizeForDislaying(html: html) { processedHtml in
                me.webView.loadHTMLString(processedHtml, baseURL: nil)
            }
        }
    }
}

// MARK: - Private

extension SecureWebViewController {

    private func preferences(javaScriptEnabled: Bool = false) -> WKPreferences {
        let createe  = WKPreferences()
        createe.javaScriptEnabled = javaScriptEnabled
        createe.minimumFontSize = minimumFontSize
        return createe
    }

    // MARK: - WKContentRuleList (block loading of all remote content)

    @available(iOS, introduced: 11.0)
    private func setupBlocklist(completion: @escaping () -> Void) {
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
            defer {
                loadGroup.leave()
            }
            if let _ = error {
                // Not finding a list is reported as an error for some reason.
                // We ignore it.
                return
            }
            compiledBlockList = loadedRuleList
        }
        loadGroup.notify(queue: DispatchQueue.main) {
            if compiledBlockList != nil {
                // We have it, set it.
                setBlocklist()
                return
            }

            // No previous blocklist found. Compile a new one.
            let blockRules = self.blockRulesJson

            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "pep.security.SecureWebViewController.block_all_external_content",
                encodedContentRuleList: blockRules) { (contentRuleList, error) in
                    if let error = error {
                        Log.shared.errorAndCrash(
                            "Compile error: %@", "\(error)")
                        return
                    }
                    compiledBlockList = contentRuleList
                    guard let _ = compiledBlockList else {
                        Log.shared.errorAndCrash(
                            "Emergency exit. External content not blocked.")
                        completion()
                        return

                    }
                    // We have it, set it.
                    setBlocklist()
            }
        }
    }

    /// Blocklist that:
    /// - blocks loading of every content. Local and remote.
    /// - only non-blockt URL type are content ids (images inlined in e-mails), which are handled
    ///     and loaded locally by CidHandler.
    private var blockRulesJson: String {
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
        "url-filter": "cid"
        },
        "action": {
        "type": "ignore-previous-rules"
        }
        }]
        """
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
            guard let url = navigationAction.request.url else {
                Log.shared.errorAndCrash("Link to nonexisting URL has been clicked?")
                break
            }
            if url.scheme == "mailto" {
                // The user clicked on an email URL.
                urlClickHandler?.didClickOn(mailToUrlLink: url)
            } else {
                // The user clicked a link type we do not allow custom handling for.
                // Try to open it in an appropriate app, do nothing if that fails.
                guard UIApplication.shared.canOpenURL(url) else {
                    break
                }
                UIApplication.shared.open(url, options: [:])
            }
        case .backForward, .formResubmitted, .formSubmitted, .reload:
            // ignore
            break
        @unknown default:
            Log.shared.errorAndCrash("Unhandled case")
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // WKWebView has just loaded its content (scripts, data) but scrollView doesn't have proper size yet
        // ScrollView needs some time to calculate own size.
        // The contentSize scrollView observer is needed to get an event
        // when the size of the scrollView content changes from CGSize.zero to final dimensions.
        webView.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            // ContentSize observer has just done its job.
            webView.scrollView.removeObserver(self, forKeyPath: "contentSize")
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }
                me.webView.frame = me.webView.scrollView.frame
                me.delegate?.didFinishLoading()
            }
        }
    }
}

// MARK: - UIScrollViewDelegate

extension SecureWebViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = zoomingEnabled
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // We disable vertical scrolling if we are not zoomed in.
        scrollingEnabled = scrollView.contentSize.width > view.frame.size.width
    }
}

// MARK: -

extension UISplitViewController {

    override open func present(_ viewControllerToPresent: UIViewController,
                               animated flag: Bool,
                               completion: (() -> Void)? = nil) {
        // We intercept if:
        // - the viewControllerToPresent is an Action Sheet
        // - the title of the action sheet is (probably) a valid email address
        guard
            let alertController = viewControllerToPresent as? UIAlertController,
            alertController.preferredStyle == .actionSheet else {
                // Is not an Action Sheet. Forward for custom handling.
                super.present(viewControllerToPresent, animated: flag, completion: completion)
                return
        }

        let alertTitle = alertController.title ?? ""

        if alertTitle.isProbablyValidEmail() {
            // It *is* an Action Sheet shown due to long-press on mailto: URL and we know the
            // clicked address.
            // Forward for custom handling.
            let mailAddress = alertTitle

            var alertRect: CGRect

            // On tablets we have a popover source rect, else we don't care because it will
            // show as action sheet
            if let rect = alertController.popoverPresentationController?.sourceRect {
                alertRect = rect
            } else {
                alertRect =  CGRect(x: 0, y: 0, width: 0, height: 0)
            }

            UIUtils.presentActionSheetWithContactOptions(forContactWithEmailAddress: mailAddress,
                                                         at: alertRect,
                                                         at: self.view)
        } else if alertTitle.hasPrefix(UrlClickHandler.Scheme.mailto.rawValue) {
            // It *is* an Action Sheet shown due to long-press on mailto: URL, but we do not know
            // the clicked address.
            // That happens due to an Apple bug. Apple passes everything prefixed with "mailto:"
            // to its Action Sheet.
            // Example:
            //          A click on "mailto:Fred%20Foo<foo@example.com>"
            //          results in
            //          alertController.title == "mailto:Fred"
            //
            // We simply ignore it as:
            //                      - we are unable to handle it due to the missing email address
            //                      - we do not want to display Apple's ActionSheet
            return
        } else {
            // Is not shown due to long-press on mailto: URL.
            // Forward for default handling.
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }
    }
}

// MARK: !! EXTREMELY DIRTY HACK !! ( END )
// MARK: -
