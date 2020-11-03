//
//  ServerType.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Server {
    public enum ServerType: Int16 {
        case imap = 0
        case smtp

        public func asString() -> String {
            switch self {
            case .imap:
                return "IMAP"
            case .smtp:
                return "SMTP"
            }
        }
    }
}
