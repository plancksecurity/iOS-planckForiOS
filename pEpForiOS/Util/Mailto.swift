//
//  Mailto.swift
//  pEp
//
//  Created by Martin Brude on 06/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PEPObjCAdapterFramework

public struct Mailto {

    private enum Pattern: String {
        case scheme = "mailto:"
        case cc = "cc="
        case bcc = "bcc="
        case body = "body="
        case subject = "subject="
    }

    /// The emails addresses for the to: field
    public var tos: [Identity]?
    /// The emails addresses for the cc: field
    public var ccs: [Identity]?
    /// The emails addresses for the bcc: field
    public var bccs: [Identity]?
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
            if !part.contains("=") {
                let components = part.components(separatedBy: ",")
                var toz = [Identity]()
                Session.main.performAndWait {
                    toz = components.map {
                        var identity: Identity
                        if let existing = Identity.by(address: $0) {
                            identity = existing
                        } else {
                            identity = Identity(address: $0)
                            identity.save()
                        }
                        return identity
                    }
                }
                tos = toz
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

        /// Parse the recipient fields (tos, ccs, bccs)
        /// - Parameters:
        ///   - part: The part of the url that contains the fields.
        ///   - pattern: The pattern ('tos', 'ccs', 'bccs', the header fields).
        /// - Returns: the email addresses for the field
        func parseRecipientField(with part: String.SubSequence, and pattern: String) -> [Identity]? {
            if part.starts(with:pattern) {
                return part.removeFirst(pattern: pattern).components(separatedBy: ",").map { return Identity(address: $0) }
            }
            return nil
        }

        /// Parse the text fields (subject and body)
        /// - Parameters:
        ///   - part: The part of the url that contains the text fields.
        ///   - pattern: The pattern ('subject' or 'body', the header fields).
        /// - Returns: The text for the field. 
        func parseTextField(with part: String.SubSequence, and pattern: String) -> String? {
            if part.starts(with: pattern) {
                return part.removeFirst(pattern: pattern)
            }
            return nil
        }
    }
}
