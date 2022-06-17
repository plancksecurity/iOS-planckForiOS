//
//  String+HTML.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

extension String {
    /**
     Extracts pure text from HTML, useful for creating snippets of a mail.
     */
    public func extractTextFromHTML(respectNewLines: Bool) -> String? {
        let parser = HtmlToTextSaxParser()
        parser.parse(string: self)
        if respectNewLines {
            return parser.output?.trimmed()
        }
        return parser.output?.replaceNewLinesWith(" ").trimmed()
    }

    /**
     Very simple markdown text from the HTML that is produced when converting
     an NSAttributedString to HTML.
     */
    public func attributedStringHtmlToMarkdown(
        imgDelegate: MarkdownImageDelegate? = nil) -> String? {
        let parser = HtmlToMarkdownSaxParser()
        parser.imgDelegate = imgDelegate
        parser.parse(string: self)
        return parser.output
    }

    public func markdownToHtml() -> String? { //!!!: ADAM: you made this dead code (and thus removed its required functionality)
        return (self as NSString)
            .nsMarkdownToHtml()? //!!!: //ADAM:
            .replacingOccurrencesOfPepSignatureWithHtmlVersion()
    }
    
    public func containsExternalContent() -> Bool {
        let pattern = """
(<img.*? src=(3D)?"((https?)|(www)).*?>)
"""
        let result = find(pattern: pattern)
        return result.count > 0
    }

    public func htmlConvertImageLinksToImageMarkdownString(html: String, attachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate? = nil) -> String {

        //Pattern to get all images tags in the current html
        let pattern = """
(<img.*?)(src.*?=.*?)(".*?")(.*?)(\\/*?>)
"""

        let results = html.find(pattern: pattern)

        var htmlConverted = html

        for result in results {
            guard let data = result.data(using: .utf16) else {
                break
            }
            let parser = HtmlTagParser(data: data)
            let src = parser.src.first ?? "empty src"
            let alt = parser.alt.first ?? ""

            htmlConverted = htmlConverted.replacingOccurrences(of: result, with: "![\(alt)](\(src))<img ")
        }

        return htmlConverted
    }

    /// Remove all font-faces (@font-face{...})
    ///
    /// We found a crash trying to show some mails because NSAttributedString has problems with external content in the html. It uses a webview under the hood.
    /// As any external content in NSAttributedString is potentially dangeurous and font-faces load fonts from external resources, this method prevents the crash.
    /// To go deeper please read https://pep.foundation/jira/browse/IOS-2434.
    public mutating func removeFontFaces() {
        removeRegexMatches(of: #"@font-face\s*\{[^}]*\}"#)
    }

    public func htmlToAttributedString(deleteInlinePictures: Bool = false,
                                       attachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate?) -> NSAttributedString {
        var htmlWithCitedChars = self

        let patternStartBlockqoute = "[<]blockquote[^>]*>(.*?)"
        let patternEndBlockqoute = "[<]/blockquote[^>]*>(.*?)"

        for result in htmlWithCitedChars.find(pattern: patternStartBlockqoute) {
            htmlWithCitedChars = htmlWithCitedChars.replacingOccurrences(of: result, with: "›")
        }
        for result in htmlWithCitedChars.find(pattern: patternEndBlockqoute) {
            htmlWithCitedChars = htmlWithCitedChars.replacingOccurrences(of: result, with: "‹")
        }

        // prepare HTML for HTML foundation framework parsing
        // we change cid to image coded with base64
        var html = htmlConvertImageLinksToImageMarkdownString(html: htmlWithCitedChars, attachmentDelegate: attachmentDelegate)
        html.removeFontFaces()

        let htmlData = html.data(using: .unicode,
                                 allowLossyConversion: true)
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] =
            [.documentType : NSAttributedString.DocumentType.html]

        guard var string = try? NSAttributedString(data: htmlData ?? Data(),
                                                         options: options,
                                                         documentAttributes: nil)
        else {
            return NSAttributedString.normalAttributedString(from: "")
        }

        let patternFindImageMarkdownSyntax = "(?:!\\[(.*?)\\]\\((.*?)\\))"
        for match in string.string.find(pattern: patternFindImageMarkdownSyntax) {

            var src = ""
            var alt = ""
            for component in match.components(separatedBy: "]") {
                if component.contains("![") {
                    alt = component.replacingOccurrences(of: "![", with: "")
                } else if component.contains("(") {
                    src = component
                        .replacingOccurrences(of: ")", with: "")
                        .replacingOccurrences(of: "(", with: "")
                } else {
                    break
                }
            }
            if let attachment = attachmentDelegate?.imageAttachment(src: src, alt: alt) {
                guard let image = attachment.image else { return string }
                let textAttachment = BodyCellViewModel.TextAttachment()
                textAttachment.image = image
                textAttachment.attachment = attachment
                let imageString = NSAttributedString(attachment: textAttachment)
                let replaceTo = deleteInlinePictures
                    ? NSAttributedString(string: "")
                    : imageString
                string = string.replacingOccurrences(ofWith: [match : replaceTo])
            }
            if deleteInlinePictures {
                string = string.replacingOccurrences(ofWith: [match : ""])
            }
        }

        return string.normalAttributedString()
    }

    public func replaceMarkdownImageSyntaxToHtmlSyntax() -> String {

        var html = self

        let patternFindImageMarkdownSyntax = "(?:!\\[(.*?)\\]\\((.*?)\\))"

        for match in self.find(pattern: patternFindImageMarkdownSyntax) {

            let htmlSyntax = "<img src=\"{src}\" alt=\"{alt}\"/>"
            var src = ""
            var alt = ""

            for component in match.components(separatedBy: "]") {
                if component.contains("![") {
                    alt = component.replacingOccurrences(of: "![", with: "")
                } else if component.contains("(") {
                    src = component
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                } else {
                    break
                }
            }

            let htmlImageSyntaxArrayFilled = htmlSyntax
                .replacingOccurrences(of: "{src}", with: src)
                .replacingOccurrences(of: "{alt}", with: alt)

            html = html.replacingOccurrences(of: match, with: htmlImageSyntaxArrayFilled)
        }
        return html
    }
}
