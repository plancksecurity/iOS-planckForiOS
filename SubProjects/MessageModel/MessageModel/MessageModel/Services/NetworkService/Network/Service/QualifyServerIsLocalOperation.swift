//
//  QualifyServerIsLocalOperation.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/// Qualifies the given server name re trusted or untrusted, depending on whether it is located
/// network-local or not.
class QualifyServerIsLocalOperation: BaseOperation {
    /// The server name to be probed for "localness".
    let serverName: String

    /// Flag indicating whether the server is local, or not.
    /// - Note: The value is only valid after running the operation.
    var isLocal: Bool?

    init(parentName: String = #function,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         serverName: String) {
        self.serverName = serverName
    }

    func isLocal(ipAddress: IPAddress) -> Bool {
        return ipAddress.isLocal()
    }

    func isRemote(ipAddress: IPAddress) -> Bool {
        return !isLocal(ipAddress: ipAddress)
    }

    override func main() {
        let ipAddresses = lookupAddresses(serverName: serverName)
        if !ipAddresses.isEmpty {
            isLocal = !ipAddresses.contains { isRemote(ipAddress: $0) }
        } else {
            isLocal = nil
        }
    }
}

// MARK: - Private & Clutter

extension QualifyServerIsLocalOperation {

    enum IPAddress {
        case ipv4(UInt8, UInt8, UInt8, UInt8)
        case ipv6(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8)

        static func ==(lhs: IPAddress, rhs: IPAddress) -> Bool {
            switch lhs {
            case let .ipv4(a1, a2, a3, a4):
                switch rhs {
                case let .ipv4(b1, b2, b3, b4):
                    return a1 == b1 && a2 == b2 && a3 == b3 && a4 == b4
                case .ipv6:
                    return false
                }
            case let .ipv6(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11,
                           a12, a13, a14, a15, a16):
                switch rhs {
                case .ipv4:
                    return false
                case let .ipv6(b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11,
                               b12, b13, b14, b15, b16):
                    return a1 == b1 && a2 == b2 && a3 == b3 && a4 == b4 &&
                        a5 == b5 && a6 == b6 && a7 == b7 && a8 == b8 &&
                        a9 == b9 && a10 == b10 && a11 == b11 && a12 == b12 &&
                        a13 == b13 && a14 == b14 && a15 == b15 && a16 == b16
                }
            }
        }

        static let localhostIPv4: IPAddress = .ipv4(127, 0, 0, 1)
        static let localhostIPv6: IPAddress = .ipv6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)

        func isLocal() -> Bool {
            switch self {
            case let .ipv4(u1, u2, _, _):
                return self == IPAddress.localhostIPv4
                    || u1 == 10
                    || u1 == 172 && u2 >= 16 && u2 <= 31
                    || u1 == 192 && u2 == 168
                    || u1 == 169 && u2 == 254
            case let .ipv6(u1, u2, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
                return self == IPAddress.localhostIPv6 || u1 == 0xfc || u1 == 0xfd ||
                    (u1 == 0xfe && (u2 >> 6) == 0x02)
            }
        }
    }

    /// Looks up the given server name.
    ///  - Returns: An array of IP addresses.
    private func lookupAddresses(serverName: String) -> [IPAddress] {
        var ipAddresses = [IPAddress]()
        let host = CFHostCreateWithName(
            nil, serverName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue()
            as NSArray?, success.boolValue {
            for case let theAddress as NSData in addresses {
                let sockAddr = theAddress.bytes.assumingMemoryBound(to: sockaddr.self)
                if sockAddr.pointee.sa_family == AF_INET6 {
                    let sockAddrIn6 = theAddress.bytes.assumingMemoryBound(to: sockaddr_in6.self)
                    let (oct1, oct2, oct3, oct4, oct5, oct6, oct7, oct8, oct9,
                        oct10, oct11, oct12, oct13, oct14, oct15, oct16) =
                            sockAddrIn6.pointee.sin6_addr.__u6_addr.__u6_addr8
                    ipAddresses.append(.ipv6(oct1, oct2, oct3, oct4, oct5, oct6, oct7, oct8,
                                             oct9, oct10, oct11, oct12, oct13, oct14, oct15, oct16))
                } else if sockAddr.pointee.sa_family == AF_INET {
                    let sockAddrIn = theAddress.bytes.assumingMemoryBound(to: sockaddr_in.self)
                    let addr = in_addr_t(bigEndian: sockAddrIn.pointee.sin_addr.s_addr)
                    let ip4Address = IPAddress.ipv4(UInt8(addr >> 24), UInt8(addr >> 16 & 255),
                                                    UInt8(addr >> 8 & 255), UInt8(addr & 255))
                    ipAddresses.append(ip4Address)
                } else {
                    Log.shared.errorAndCrash("unknown address family")
                }
            }
        }
        return ipAddresses
    }
}
