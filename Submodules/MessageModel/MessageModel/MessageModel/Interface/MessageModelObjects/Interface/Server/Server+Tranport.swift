//
//  Server+Tranport.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Server {
    public enum Transport: Int16, CaseIterable {
        case plain
        case tls
        case startTls

        //MB: Rm this
        public init?(fromString: String?) {
            guard let s = fromString else {
                return nil
            }
            switch s {
            case "Plain":
                self.init(rawValue: 0)
            case "SSL/TLS":
                self.init(rawValue: 1)
            case "StartTLS":
                self.init(rawValue: 2)
            default:
                return nil
            }
        }

        public func asString() -> String {
            switch self {
            case .plain:
                return "Plain"
            case .tls:
                return "SSL/TLS"
            case .startTls:
                return "StartTLS"
            }
        }

        public static var numberOfOptions: Int {
            get {
                return Transport.allCases.count
            }
        }

        //MB:- RM this
        public static func toArray() -> [Transport] {
            var transportOptions = [Transport]()
            for index in 0...Transport.numberOfOptions {
                if let transport = Transport(rawValue: Int16(index)) {
                    transportOptions.append(transport)
                }
            }
            return transportOptions
        }
    }
}
