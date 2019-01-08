//
//  WebViewNoJS.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit

protocol SecureWebViewControllerDelegate: class {
    /// Called on content size changes while within loading time.
    /// - Parameters:
    ///   - webViewController: calling view controller
    ///   - sizeChangedTo: webview.scrollview.contentSize after loading html content and layouting
    func secureWebViewController(_ webViewController: SecureWebViewController,
                                 sizeChangedTo size: CGSize)
}

protocol SecureWebViewUrlClickHandlerProtocol: class {
    /// Called whenever a mailto:// URL has been clicked by the user.
    /// - Parameters:
    ///   - sender: caller of the message
    ///   - mailToUrlClicked: the clicked URL
    func secureWebViewController(_ webViewController: SecureWebViewController,
                                 didClickMailToUrlLink url: URL)
}

/// Webview that does not:
/// - excecute JS
/// - load any remote content
/// Note: It is insecure to use this class on iOS < 11. Thus it will intentionally take the
/// emergency exit and crash when trying to use it running iOS < 11.
class SecureWebViewController: UIViewController {
    static let storyboardId = "SecureWebViewController"

    weak var delegate: SecureWebViewControllerDelegate?
    weak var urlClickHandler: SecureWebViewUrlClickHandlerProtocol?

    var zoomingEnabled: Bool = true

    private var _userInteractionEnabled: Bool = true
    var userInteractionEnabled: Bool {
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

    private var _scrollingEnabled: Bool = false
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

    static var isSaveToUseWebView: Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }

    private var webView: WKWebView!
    private var sizeChangeObserver: NSKeyValueObservation?

    /// webview.scrollView.contentSize after html has finished loading and layouting
    private(set) var contentSize: CGSize?

    /// Assumed max time it can take to load a page.
    /// After this time content size changes are not reported any more.
    static private let maxLoadingTime: TimeInterval = 0.5
    /// Last time a size change has been reported to
    private var lastReportedSizeUpdate: Date?

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
        prefs.javaScriptEnabled = false
        config.preferences = prefs
        // This handler provides local content for cid: URLs
        CidHandler.setup(config: config)
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.isScrollEnabled = scrollingEnabled
        webView.scrollView.isUserInteractionEnabled = userInteractionEnabled
        view = webView
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

    // MARK: - Handle Content Size Changes

    private var isContentLoadedAndLayouted: Bool {
        if let sinceUpdate = lastReportedSizeUpdate?.timeIntervalSinceNow,
            -sinceUpdate > SecureWebViewController.maxLoadingTime {
            // We assuem initial loading is done.
            // The size change must be zooming triggered by user.
            return true
        }
        return false
    }

    private func informDelegateAfterLoadingFinished() {
        // code to run whenever the content(size) changes
        let handler = {
            [weak self] (scrollView: UIScrollView, change: NSKeyValueObservedChange<CGSize>) in
            guard let me = self else {
                Logger.lostMySelf(category: Logger.backend)
                return
            }

            if me.isContentLoadedAndLayouted {
                // We assuem initial loading is done.
                // The size change must be zooming triggered by user.
                return
            }

            guard
                let contentSize = change.newValue,
                !me.shouldIgnoreContentSizeChange(newSize: contentSize) else {
                    return
            }
            me.contentSize = contentSize
            me.lastReportedSizeUpdate = Date()
            me.delegate?.secureWebViewController(me, sizeChangedTo: contentSize)
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

    // MARK: - HTML TWEAKS

    /// Prepares the html string for displaying.
    ///
    /// - Parameter html: html to prepare
    /// - Returns: html ready for displaying
    private func preprocess(html: String) -> String {
        var result = html
        result = htmlTagsAssured(html: result)
        result = tweakedHtml(inHtml: result)
        return result
    }

    /// Returns a modified version of the given html, adjusted to:
    /// - simulate "PageScaleToFit" layout behaviour
    /// - responsive image size
    /// - set default link color to pEp color
    ///
    /// - Parameter html: html string that should be tweaked for nicer display
    /// - Returns: tweaked html
    private func tweakedHtml(inHtml html: String) -> String {
        var html = html
        // Remove existing viewport definitions that are pontentially unsupported by WKWebview.
        html.removeRegexMatches(of: "<meta name=\\\"viewport\\\".*?>")
        // Define viewport WKWebview can deal with
        let screenWidth = UIScreen.main.bounds.width
        let scaleToFitHtml =
        "<meta name=\"viewport\" content=\"width=\(screenWidth), shrink-to-fit=YES\"/>"
        // Build HTML tweak
        let styleResponsiveImageSize = """
            img {
                max-width: 100%;
                height: auto;
            }
        """
        let styleLinkStyle = """
            a:link {
                color:\(UIColor.pEpDarkGreenHex);
                text-decoration: underline;
        }
        """
        let tweak = """
            \(scaleToFitHtml)
            <style>
                \(styleResponsiveImageSize)
                \(styleLinkStyle)
            </style>
        """
        // Inject tweak if appropriate
        var result = html

        if html.contains(find: "<head>") {
            result = html.replacingOccurrences(of: "<head>", with:
                """
                <head>
                \(tweak)
                """)
        } else if html.contains(find: "<html>") {
            result = html.replacingOccurrences(of: "<html>", with:
                """
                <html>
                    <head>
                        \(tweak)
                    </head>
                """
            )
        }
        return result
    }

    /// Assures a given string is wrapped in html tags (<html> givenString </html>).
    ///
    /// - Parameter html: string to assure its wrapped in html tags
    /// - Returns: wrapped string
    private func htmlTagsAssured(html: String) -> String {
        let startHtml = "<html>"
        let endHtml = "</html>"
        var result = html
        if !html.contains(find: startHtml) {
            result = startHtml + html + endHtml
        }
        return result
    }

    // MARK: - API

    func display(htmlString: String) {
        guard #available(iOS 11.0, *) else {
            return
        }
        let displayHtml = preprocess(html: htmlString)
        setupBlocklist() {
            self.webView.loadHTMLString(displayHtml, baseURL: nil)
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
            guard let url = navigationAction.request.url else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "Link to nonexisting URL has been clicked?")
                break
            }
            if url.scheme == "mailto" {
                // The user clicked on an email URL.
                urlClickHandler?.secureWebViewController(self, didClickMailToUrlLink: url)
            } else {
                // The user clicked a links we do not allow custom handling for.
                // Try to open it in an appropriate app, do nothing if that fails.
                guard UIApplication.shared.canOpenURL(url) else {
                    break
                }
                UIApplication.shared.openURL(url)
            }
        case .backForward, .formResubmitted, .formSubmitted, .reload:
            // ignore
            break
        }
        decisionHandler(.cancel)
    }
}

// MARK: - UIScrollViewDelegate

extension SecureWebViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = isContentLoadedAndLayouted && zoomingEnabled
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // We disable vertical scrolling if we are not zoomed in.
        scrollingEnabled = scrollView.contentSize.width > view.frame.size.width
    }
}

// MARK: -
// MARK: !! EXTREMELY DIRTY HACK !! ( START )

/// This is the only hack found to intercept WKWebViews default long-press on mailto: URL
/// behaviour.
/// !! IF YOU ARE AWARE OF A BETTER SOLUTION, PLEASE LET US KNOW OR IMPLEMENT !!
/// We must intercept it to show our custom action sheet.
/// The hack overrrides present(...) in the root view controller of the App (!).

extension SecureWebViewController {
    /// DIRTY HACK. Find details in below UISplitViewController extension
    static var appConfigDirtyHack: AppConfig?
}
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

        if alertTitle.isProbablyValidEmail(),
            let appConfig = SecureWebViewController.appConfigDirtyHack {
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
                                                         on: self,
                                                         at: alertRect,
                                                         at: self.view,
                                                        appConfig: appConfig)
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
            // Forward for custom handling.
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }
    }
}

// MARK: !! EXTREMELY DIRTY HACK !! ( END )
// MARK: -
