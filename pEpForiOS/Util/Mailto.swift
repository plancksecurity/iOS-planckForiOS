//
//  Mailto.swift
//  pEp
//
//  Created by Martin Brude on 06/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

struct Mailto {

    enum Pattern: String {
        case scheme = "mailto:"
        case cc = "cc="
        case bcc = "bcc="
        case body = "body="
        case subject = "subject="
    }

    private let commaSeparator = ","
    private let equalsSeparator = "="

    /// The emails addresses for the to: field
    public var tos: [String]?
    /// The emails addresses for the cc: field
    public var ccs: [String]?
    /// The emails addresses for the bcc: field
    public var bccs: [String]?
    /// The subject of the email
    public var subject: String?
    /// The body of the email
    public var body: String?

    private var url: URL

    init?(url : URL) {
        self.url = url
        guard url.isMailto else {
            return nil
        }
        let content = url.absoluteString.removeFirst(pattern: Pattern.scheme.rawValue)
        let parts = content.split {$0 == "&" || $0 == "?"}
        parts.forEach { (part) in
            if !part.contains(equalsSeparator) {
                tos = part.componentsSeparatedByComma()
            } else if let ccs = parseRecipientField(with: part, and: Pattern.cc.rawValue) {
                self.ccs = ccs
            } else if let bccs = parseRecipientField(with: part, and: Pattern.bcc.rawValue) {
                self.bccs = bccs
            } else if let body = parseTextField(with: part, and:  Pattern.body.rawValue) {
                self.body = body
            } else if let subject = parseTextField(with: part, and: Pattern.subject.rawValue) {
                self.subject = subject
            }
        }

        func parseRecipientField(with part: String.SubSequence, and pattern: String) -> [String]? {
            if part.starts(with:pattern) {
                return part.removeFirst(pattern: pattern).componentsSeparatedByComma()
            }
            return nil
        }

        func parseTextField(with part: String.SubSequence, and pattern: String) -> String? {
            if part.starts(with: pattern) {
                return part.removeFirst(pattern: pattern)
            }
            return nil
        }
    }

    public var description: String {
        return url.absoluteString
    }
}
