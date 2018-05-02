//
//  QualifyServerIsLocalOperation.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Qualifies the given server name re trusted or untrusted, depending on
 whether it is located network-local or not.
 */
class QualifyServerIsLocalOperation: ConcurrentBaseOperation {
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

        static let localhostIPv6: IPAddress = .ipv6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)
    }

    /**
     The server name to be probed for "localness".
     */
    public let serverName: String

    /**
     Flag indicating whether the server is local, or not.
     - Note: The value is only valid after running the operation.
     */
    public var isLocal: Bool?

    let ipParser = IPAddressParser()

    init(parentName: String = #function,
         errorContainer: ServiceErrorProtocol = ErrorContainer(),
         serverName: String) {
        self.serverName = serverName
    }

    /**
     Looks up the given server name.
     - Returns: An array of IP addresses.
     */
    func lookupAddresses(serverName: String) -> [IPAddress] {
        var ipAddresses = [IPAddress]()
        let host = CFHostCreateWithName(
            nil, serverName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue()
            as NSArray?, success.boolValue {
            for case let theAddress as NSData in addresses {
                let sockAdr = theAddress.bytes.assumingMemoryBound(to: sockaddr.self)
                if sockAdr.pointee.sa_family == AF_INET6 {
                    let sockAddrIn6 = theAddress.bytes.assumingMemoryBound(to: sockaddr_in6.self)
                    let (oct1, oct2, oct3, oct4, oct5, oct6, oct7, oct8, oct9,
                        oct10, oct11, oct12, oct13, oct14, oct15, oct16) =
                            sockAddrIn6.pointee.sin6_addr.__u6_addr.__u6_addr8
                    ipAddresses.append(.ipv6(oct1, oct2, oct3, oct4, oct5, oct6, oct7, oct8,
                                             oct9, oct10, oct11, oct12, oct13, oct14, oct15, oct16))
                } else if sockAdr.pointee.sa_family == AF_INET {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self),
                                   socklen_t(theAddress.length),
                                   &hostname, socklen_t(hostname.count),
                                   nil,
                                   0, NI_NUMERICHOST) == 0 {
                        if let ip4Octets = ipParser.octetsIPv4(
                            ipAddress: String(cString: hostname)),
                            ip4Octets.count == 4 {
                            ipAddresses.append(.ipv4(ip4Octets[0], ip4Octets[1], ip4Octets[2],
                                                     ip4Octets[3]))
                        } else {
                            Log.shared.errorAndCrash(
                                component: #function,
                                errorString: "could not parse result from getnameinfo into IPv4 address parts")
                        }
                    } else {
                        Log.shared.errorAndCrash(component: #function,
                                                 errorString: "getnameinfo didn't work")
                    }
                } else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "unknown address family")
                }
            }
        }
        return ipAddresses
    }

    func isLocal(ipAddress: IPAddress) -> Bool {
        switch ipAddress {
        case let .ipv4(u1, u2, u3, u4):
            let localhost: [CountableClosedRange<UInt8>] = [127...127, 0...0, 0...0, 1...1]
            let prefix10: [CountableClosedRange<UInt8>] = [10...10, 0...255, 0...255, 0...255]
            let prefix172: [CountableClosedRange<UInt8>] = [172...172, 16...31, 0...255, 0...255]
            let prefix192: [CountableClosedRange<UInt8>] = [192...192, 168...168, 0...255, 0...255]
            let checkedOctets = ipParser.checkSome(
                octets: [u1, u2, u3, u4],
                listOfRanges: [localhost, prefix10, prefix172, prefix192])
            return checkedOctets != nil
        case let .ipv6(u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, u16):
            print("ipv6")
            return ipAddress == IPAddress.localhostIPv6
        }
    }

    func isRemote(ipAddress: IPAddress) -> Bool {
        return !isLocal(ipAddress: ipAddress)
    }

    override func main() {
        let queue = DispatchQueue.global()
        queue.async { [weak self] in
            if let theSelf = self {
                let ipAddresses = theSelf.lookupAddresses(serverName: theSelf.serverName)
                if !ipAddresses.isEmpty {
                    theSelf.isLocal = !ipAddresses.contains { theSelf.isRemote(ipAddress: $0) }
                } else {
                    theSelf.isLocal = nil
                }
            }
            self?.markAsFinished()
        }
    }
}
