//
//  Server+Tranport.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Server {
    public enum Transport: Int16 {
        case plain
        case tls
        case startTls

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

        public static var size: Int {
            get {
                return 3
            }
        }

        public static func toArray() -> [Transport] {
            var array = [Transport]()
            for index in 0...Transport.size {
                if let transport = Transport(rawValue: Int16(index)) {
                    array.append(transport)
                }
            }
            return array
        }
    }
}
