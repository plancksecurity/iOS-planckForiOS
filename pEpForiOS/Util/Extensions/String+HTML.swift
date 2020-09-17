//
//  String+HTML.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

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

    public func htmlConvertImageLinksToImageMarkdownString(html: String, attachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate? = nil) -> String {

        let pattern = "<img\\b(?=\\s)(?=(?:[^>=]|='[^']*'|=\"[^\"]*\"|=[^'\"][^\\s>]*)*?\\ssrc\\s*=\\s*['\"]([^\"]*)['\"]?)(?:[^>=]|='[^']*'|=\"[^\"]*\"|=[^'\"\\s]*)*\"\\s?\\/?>"

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
        let html = htmlConvertImageLinksToImageMarkdownString(html: htmlWithCitedChars, attachmentDelegate: attachmentDelegate)
        let htmlData = html.data(using: .utf8,
                                 allowLossyConversion: true)
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] =
            [.documentType : NSAttributedString.DocumentType.html]
        guard let attribString = try? NSAttributedString(data: htmlData ?? Data(),
                                                   options: options,
                                                   documentAttributes: nil) else {
                                                    return NSAttributedString(string: "")
        }

        var string = NSAttributedString(attributedString: attribString)

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
                let textAttachment = TextAttachment()
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

        return string
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
