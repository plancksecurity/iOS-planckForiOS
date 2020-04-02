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


//
// WKContentRuleList is not available below iOS11, thus remote content would be loaded
// which is considered as inaceptable for a secure web view.
@available(iOS 11.0, *)
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

    public var minimumFontSize: CGFloat = 16.0

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
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }

            guard
                let contentSize = change.newValue,
                !me.shouldIgnoreContentSizeChange(newSize: contentSize) else {
                    return
            }

            if contentSize.width == me.view.bounds.width {
                // In case there is no zoom but the vertical size still changed
                me.contentSize = contentSize
                me.lastReportedSizeUpdate = Date()
                me.delegate?.secureWebViewController(me, sizeChangedTo: contentSize)
            }
            else {
                if me.isContentLoadedAndLayouted {
                    // We assuem initial loading is done.
                    // The size change must be zooming triggered by user.
                    return
                }
                
                
                me.contentSize = contentSize
                me.lastReportedSizeUpdate = Date()
                me.delegate?.secureWebViewController(me, sizeChangedTo: contentSize)
            }
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
    /// - Parameters:
    ///   - html: html to prepare
    ///   - completion: called when done. Passes the HTML ready for displaying.
    ///                 Is guaranteed to be called on the main queue.
    private func preprocess(html: String, completion: @escaping (String)->Void) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                completion(html)
                return
            }
            var result = html
            result = ReplyUtil.htmlWithVerticalLinesForBlockQuotesInjected(html: result)
            result = me.htmlTagsAssured(html: result)

            result = me.htmlWithFixedWithReplaxedWithMaxWidth(inHtml: result)
            //        result.removeRegexMatches(of: "<table.*?</table>")
            //        result.removeRegexMatches(of: "<blockquote?s:.</blockquote>")
            result = me.htmlOptimizedForDisplay(inHtml: result)

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    /// Replaces fixed `width`values with `max-width: 100%`.
    /// - note: this is an expensive task for long HTML.
    private func htmlWithFixedWithReplaxedWithMaxWidth(inHtml html: String) -> String {
        // I get non spam mails with >100.000 chars. Matching regex can not handle them. It never
        // returns, thus we show the an empty mail.
        let numCharsForIsTooExpensiveToParse = 80000
        guard html.count < numCharsForIsTooExpensiveToParse else {
            return html
        }
        var result = html
        let fixedWidthInCssPattern = #"\{[\S\s]*(?<rangeName>width:.*?px;)[\S\s]*\}"#
        guard let fixedWidthCssRegex = try? NSRegularExpression(pattern: fixedWidthInCssPattern,
                                                                options: NSRegularExpression.Options.caseInsensitive)
            else {
                Log.shared.errorAndCrash("Wrong pattern")
                return result
        }

        let fixedWidthCssMatches = fixedWidthCssRegex.matches(in: html,
                                                              options: [],
                                                              range: html.wholeRange())
        for fixedWidthCssMatch in fixedWidthCssMatches {
            let captureRange = fixedWidthCssMatch.range(withName: "rangeName")
            let tmpResultNsString = result as NSString // Required to use NSRange in next line
            result = tmpResultNsString.replacingCharacters(in: captureRange,
                                                           with: "max-width: 100% !important;")
        }

        return result
    }

    /// Returns a modified version of the given html, adjusted to:
    /// - simulate "PageScaleToFit" layout behaviour
    /// - responsive image size
    /// - set default link color to pEp color
    /// - Fixed `width:` replaced in CSS
    ///
    /// - Parameter html: html string that should be tweaked for nicer display
    /// - Returns: tweaked html
    private func htmlOptimizedForDisplay(inHtml html: String) -> String {
        var html = html
        // Remove existing viewport definitions that are pontentially unsupported by WKWebview.
        html.removeRegexMatches(of: "<meta name=\\\"viewport\\\".*?>")


        // Define viewport WKWebview can deal with
        let screenWidth = UIScreen.main.bounds.width
//        let scaleToFitHtml =
//        "<meta name=\"viewport\" content=\"width=\(screenWidth), shrink-to-fit=YES\"/>"
        let scaleToFitHtml =
        "<meta name=\"viewport\" content=\"width=\(screenWidth)\", initial-scale=1.0/>"

        // Build HTML tweak

        let wordWrap = "word-wrap: break-word;"
        let styleBodyOptimize = """
            body {
                font-family: "San Francisco" !important;
                font-size: \(minimumFontSize);
                max-width: 100% !important;
                min-width: 100% !important;
            }
        """

        let styleTableOptimize = """
            table {
                max-width: 100% !important;
            }
        """

                    //BUFF: rm! useless
                    //        let styleTableRowOptimize = """
                    //            tr {
                    //                \(wordWrap)
                    //            }
                    //        """
                    //
                    //        let styleTableCellOptimize = """
                    //           td {
                    //               \(wordWrap)
                    //           }
                    //        """

                    //BUFF: rm! breaks things
                    //        let styleParagraphOptimize = """
                    //            p {
                    //                width: \(screenWidth)pt !important;
                    //            }
                    //            """

                    //BUFF: rm! useless
                    //        let styleBlockquoteOptimize = """
                    //            blockquote {
                    //                max-width: \(screenWidth)pt !important;
                    //            }
                    //        """

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
                \(wordWrap)
        }
        """

        let tweak = """
            \(scaleToFitHtml)
            <style>
                \(styleBodyOptimize)
                \(styleTableOptimize)



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
        if !html.contains(find: endHtml) {
            result = startHtml + html + endHtml
        }
        return result
    }

    // MARK: - API

    func display(html: String) {
        setupBlocklist() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.preprocess(html: html) { processedHtml in
                me.webView.loadHTMLString(processedHtml, baseURL: nil)
            }
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
                Log.shared.errorAndCrash("Link to nonexisting URL has been clicked?")
                break
            }
            if url.scheme == "mailto" {
                // The user clicked on an email URL.
                urlClickHandler?.secureWebViewController(self, didClickMailToUrlLink: url)
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
