//
//  Mailto.swift
//  pEp
//
//  Created by Martin Brude on 06/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

public struct Mailto {

    private enum Pattern: String {
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

    /// Optional initializer. Returns nil if the url is not mailto.
    ///
    /// - Parameter url: The mailto url.
    init?(url : URL) {
        guard url.isMailto else {
            return nil
        }
        let content = url.absoluteString.removeFirstOccurrence(of: Pattern.scheme.rawValue)
        let parts = content.split {$0 == "&" || $0 == "?"}
        parts.forEach { (part) in
            if !part.contains(equalsSeparator) {
                tos = part.components(separatedBy: ",")
            } else if let ccs = parseRecipientField(with: part, and: Pattern.cc.rawValue) {
                self.ccs = ccs
            } else if let bccs = parseRecipientField(with: part, and: Pattern.bcc.rawValue) {
                self.bccs = bccs
            } else if let body = parseTextField(with: part, and: Pattern.body.rawValue) {
                self.body = body.removingPercentEncoding
            } else if let subject = parseTextField(with: part, and: Pattern.subject.rawValue) {
                self.subject = subject.removingPercentEncoding
            }
        }

        func parseRecipientField(with part: String.SubSequence, and pattern: String) -> [String]? {
            if part.starts(with:pattern) {
                return part.removeFirst(pattern: pattern).components(separatedBy: ",")
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
}
