//
//  HtmlTagParser.swift
//  pEp
//
//  Created by Adam Kowalski on 13/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

class HtmlTagParser: NSObject, XMLParserDelegate {

    private let parser: XMLParser
    private var currentTag: String = ""
    private var tree: [String : Int] = [:]
    public var htmlString = NSMutableString(string: "")
    public var htmlStringWithCitation = NSMutableString(string: "")
    public var src: [String] = []
    public var alt: [String] = []

    init(data: Data) {
        parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
        parser.parse()
    }

    private func treeIncrease(key: String) {
        tree[key] = tree[key] ?? 0 + 1
    }

    private func treeDecrease(key: String) {
        tree[key] = tree[key] ?? 0 > 0 ? tree[key] ?? 0 - 1 : 0
    }

    private func treeNthChild(key: String) -> Int {
        return tree[key] ?? 0
    }

    func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) {
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "meta" {
            parser.abortParsing()
        }
        switch elementName {
        case "meta":
            parser.abortParsing()
        case "img":
            if attributeDict.keys.contains("src") {
                src.append(attributeDict["src"] ?? "")
            }
            if attributeDict.keys.contains("alt") {
                alt.append(attributeDict["alt"] ?? "")
            }
        case "div":
            htmlStringWithCitation.append("<blockquote>")
        default:
            break
        }
        currentTag = elementName
        treeIncrease(key: elementName)
        htmlString.append("<\(elementName)>")
        htmlStringWithCitation.append("<\(elementName)>")

    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        htmlString.append(string)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentTag = ""
        treeDecrease(key: elementName)
        htmlString.append("<\\\(elementName)>")
    }

    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    }
}
