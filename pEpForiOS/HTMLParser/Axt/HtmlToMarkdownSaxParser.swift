//
//  HtmlToMarkdownSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

public protocol HtmlToMarkdownSaxParserImageDelegate: class {
    /** Let the delegate rewrite the src and alt of images */
    func img(src: String, alt: String?) -> (String, String)
}

class HtmlToMarkdownSaxParser: NSObject {
    weak var imgDelegate: HtmlToMarkdownSaxParserImageDelegate?
    var output: String?

    var acceptCharacters = false

    func parse(string: String) {
        let parser = AXHTMLParser(htmlString: string)
        parser.delegate = self
        let success = parser.parse()
        if !success {
            output = nil
        }
    }

    func add(string: String) {
        output = "\(output ?? "")\(string)"
    }

    func addImg(src: String, alt: String?) {
        add(string: "![\(alt ?? "")](\(src))]")
    }
}

extension HtmlToMarkdownSaxParser: AXHTMLParserDelegate {
    func parser(_ parser: AXHTMLParser, didStartElement elementName: String,
                attributes attributeDict: [AnyHashable : Any] = [:]) {
        if elementName == "body" {
            acceptCharacters = true
        } else if elementName == "img" {
            if let src = attributeDict["src"] as? String {
                let alt = attributeDict["alt"] as? String
                if let (newSrc, newAlt) = imgDelegate?.img(src: src, alt: alt) {
                    addImg(src: newSrc, alt: newAlt)
                } else {
                    addImg(src: src, alt: alt)
                }
            }
        } else if elementName == "br" {
            add(string: "\n")
        }
    }

    func parser(_ parser: AXHTMLParser, didEndElement elementName: String) {
        if elementName == "body" {
            acceptCharacters = false
        }
    }

    func parser(_ parser: AXHTMLParser, foundCharacters string: String) {
        if acceptCharacters {
            add(string: string.replaceNewLinesWith(""))
        }
    }

    func parser(_ parser: AXHTMLParser, parseErrorOccurred parseError: Error) {
        Log.shared.error(component: #function, error: parseError)
    }
}
