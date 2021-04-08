//
//  OptimizeHtmlForDisplayUtil.swift
//  pEp
//
//  Created by Andreas Buff on 03.04.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

protocol HtmlOptimizerUtilProtocol {
    /// Optimizes a given HTML for displaying.
    /// The optimization process might or might not (depending on the HTML) process heavy parsing
    /// (expensive). Thus we process in background with highest priority.
    /// - Parameters:
    ///   - html: html to optimize
    ///   - completion: called when done. Passes the HTML ready for displaying.
    ///                 Is guaranteed to be called on the main queue.
    func optimizeForDislaying(html: String, completion: @escaping (String)->Void)
}

/// Tool for optimizing HTML for best UX.
class HtmlOptimizerUtil: HtmlOptimizerUtilProtocol {
    private var minimumFontSize: CGFloat

    init(minimumFontSize: CGFloat = 16.0) {
        self.minimumFontSize = minimumFontSize
    }
    public func optimizeForDislaying(html: String, completion: @escaping (String)->Void) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                completion(html)
                return
            }
            var result = html
            result = ReplyUtil.htmlWithVerticalLinesForBlockQuotesInjected(html: result)
            result = me.htmlTagsAssured(html: result)
            result = me.htmlOptimizedForDisplay(inHtml: result)

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

// MARK: - Private

extension HtmlOptimizerUtil {

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
        html.removeFontFaces()

        // Define viewport WKWebview can deal with
        let screenWidth = UIScreen.main.bounds.width
        //        let scaleToFitHtml =
        //        "<meta name=\"viewport\" content=\"width=\(screenWidth), shrink-to-fit=YES\"/>"
        let scaleToFitHtml =
        "<meta name=\"viewport\" content=\"width=\(screenWidth)\", initial-scale=1.0/>"

        // Build HTML tweak

        let styleAutodetectLightOrDarkMode = """
            @media (prefers-color-scheme: dark) {
                body {
                    color: #eee;
                    background: #121212;
                }
            }
        """

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
        word-break: break-all; !important;
        }
        """

        let tweak = """
        \(scaleToFitHtml)
        <style>
        \(styleAutodetectLightOrDarkMode)
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

    // Commented but keep for a while.
    // Background:
    // * We have exatly one problem mails that uses a fixed width (swica.eml in IOS-2195).
    // * This method is very expensive (parsing HTML and replacing fixed widths).
    // * Calling this method for long (80.000+ charactes) HTML on older devices causes minor glitches on older devices.
    // Thus we decided to not do it with the cost that this one mail is not shown nicely.
    // We keep the code for a while. In case it turns
    /// Replaces fixed `width`values with `max-width: 100%`.
    /// - note: this is an expensive task for long HTML.
    //    private func htmlWithFixedWithReplaxedWithMaxWidth(inHtml html: String) -> String {
    //        // I get non spam mails with >100.000 chars. Matching regex can not handle them. It never
    //        // returns, thus we show the an empty mail.
    //        let numCharsForIsTooExpensiveToParse = 80000
    //        guard html.count < numCharsForIsTooExpensiveToParse else {
    //            return html
    //        }
    //        var result = html
    //        let fixedWidthInCssPattern = #"\{[\S\s]*(?<rangeName>width:.*?px;)[\S\s]*\}"#
    //        guard let fixedWidthCssRegex = try? NSRegularExpression(pattern: fixedWidthInCssPattern,
    //                                                                options: NSRegularExpression.Options.caseInsensitive)
    //            else {
    //                Log.shared.errorAndCrash("Wrong pattern")
    //                return result
    //        }
    //
    //        let fixedWidthCssMatches = fixedWidthCssRegex.matches(in: html,
    //                                                              options: [],
    //                                                              range: html.wholeRange())
    //        for fixedWidthCssMatch in fixedWidthCssMatches {
    //            let captureRange = fixedWidthCssMatch.range(withName: "rangeName")
    //            let tmpResultNsString = result as NSString // Required to use NSRange in next line
    //            result = tmpResultNsString.replacingCharacters(in: captureRange,
    //                                                           with: "max-width: 100% !important;")
    //        }
    //
    //        return result
    //    }
}
