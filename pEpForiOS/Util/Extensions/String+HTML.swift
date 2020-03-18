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

    public func markdownToHtml() -> String? {
        return (self as NSString)
            .nsMarkdownToHtml()?
            .replacingOccurrencesOfPepSignatureWithHtmlVersion()
    }

    public func htmlToAttributedStringApple() -> NSAttributedString {

        // HTML Foundation framework
        let htmlData = self.data(using: .utf16,
                                 allowLossyConversion: true)
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] =
            [.documentType : NSAttributedString.DocumentType.html]
        let attribString = try! NSAttributedString(data: htmlData ?? Data(),
                                                   options: options,
                                                   documentAttributes: nil)
        return attribString
    }

    public func htmlConvertImageLinksToImageBase64(html: String, attachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate? = nil) -> String {

        let pattern = "<img\\b(?=\\s)(?=(?:[^>=]|='[^']*'|=\"[^\"]*\"|=[^'\"][^\\s>]*)*?\\ssrc=['\"]([^\"]*)['\"]?)(?:[^>=]|='[^']*'|=\"[^\"]*\"|=[^'\"\\s]*)*\"\\s?\\/?>"

        let imageBaseMetaTags = "data:image/png;cid:{cid};charset=utf-8;base64,"

        let results = matches(text: html, pattern: pattern)

        var htmlImgToBase64Converted = html

        for result in results {
            guard let data = result.data(using: .utf16) else {
                break
            }
            let parser = HtmlTagParser(data: data)
            let src = parser.src.first ?? "empty src"
            let alt = parser.alt.first ?? "empty alt"

            if let attachment = attachmentDelegate?.imageAttachment(src: src, alt: alt),
                let image = attachment.image,
                let imageData = image.pngData() {
                let imageBase64 = imageData.base64EncodedString()
                htmlImgToBase64Converted = htmlImgToBase64Converted
                    .replacingOccurrences(of: src, with: imageBaseMetaTags + imageBase64)
                    .replacingOccurrences(of: "cid:{cid}", with: src)
            }
        }

        return htmlImgToBase64Converted
    }

    public func htmlConvertImageBase64ToImageCidReference(html: String) -> String {

        let pattern = "<img\\b(?=\\s)(?=(?:[^>=]|='[^']*'|=\"[^\"]*\"|=[^'\"][^\\s>]*)*?\\ssrc=['\"]([^\"]*)['\"]?)(?:[^>=]|='[^']*'|=\"[^\"]*\"|=[^'\"\\s]*)*\"\\s?\\/?>"

        let imageBaseMetaTags = "data:image/png;cid:{cid};charset=utf-8;base64,"

        let results = matches(text: html, pattern: pattern)

        var htmlImgToBase64Converted = html

        for result in results {
            guard let data = result.data(using: .utf16) else {
                break
            }
            let parser = HtmlTagParser(data: data)
            let src = parser.src.first ?? "empty src"
            let alt = parser.alt.first ?? "empty alt"
            if src.contains(find: "data:image/png;cid:") {
                let cidReference = src.components(separatedBy: ":")
                htmlImgToBase64Converted = htmlImgToBase64Converted.replacingOccurrences(of: src, with: "")
            }
        }

        return htmlImgToBase64Converted
    }

    func matches(text: String, pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let string = NSString(string: text)
            let results = regex.matches(in: text, range: NSMakeRange(0, string.length))
            return results.map { string.substring(with: $0.range) }
        } catch let error {
            print("Error, maybe invalid regex: " + error.localizedDescription)
        }
        return []
    }

    public func htmlToAttributedString(attachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate?) -> NSAttributedString {

        let htmlWithCitedChar = self

        // prepare HTML for HTML foundation framework parsing
        // we change cid to image coded with base64
        let html = htmlConvertImageLinksToImageBase64(html: htmlWithCitedChar, attachmentDelegate: attachmentDelegate)
        let htmlData = html.data(using: .utf16,
                                 allowLossyConversion: false)
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] =
            [.documentType : NSAttributedString.DocumentType.html]
        let attribString = try? NSAttributedString(data: htmlData ?? Data(),
                                                   options: options,
                                                   documentAttributes: nil)

        return attribString ?? NSAttributedString(string: "")

//        // get only images
//        let parser = HtmlToAttributedTextSaxParser()
//        parser.attachmentDelegate = attachmentDelegate
//        parser.parse(string: self)
//        return parser.attributedOutput
    }
}
