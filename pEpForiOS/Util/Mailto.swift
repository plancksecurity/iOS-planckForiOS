//
//  Mailto.swift
//  pEp
//
//  Created by Martin Brude on 06/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

struct Mailto {
    /// The emails addresses for the to: field
    var tos: [String]?
    /// The emails addresses for the cc: field
    var ccs: [String]?
    /// The emails addresses for the bcc: field
    var bccs: [String]?
    /// The subject of the email
    var subject: String?
    /// The body of the email
    var body: String?

    init?(url : URL) {
        guard url.isMailto else {
            return nil
        }
        let content = url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
        let parts = content.split {$0 == "&" || $0 == "?"}
        parts.forEach { (part) in
            if !part.contains("=") {
                tos = part.split {$0 == "," }.map { String($0) }
            }
            if part.starts(with:"cc=") {
                let ccCleaned = part.replaceFirst(of: "cc=", with: "")
                ccs = ccCleaned.split {$0 == "," }.map { String($0) }
            }
            if part.contains("bcc=") {
                let bccCleaned = part.replaceFirst(of: "bcc=", with: "")
                bccs = bccCleaned.split {$0 == "," }.map { String($0) }
            }
            if part.starts(with:"body=") {
                body = part.replaceFirst(of: "body=", with: "")
            }
            if part.starts(with:"subject=") {
                subject = part.replaceFirst(of: "subject=", with: "")
            }
        }
    }
}
