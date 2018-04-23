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
    /**
     The server name to be probed for "localness".
     */
    public let serverName: String

    /**
     Flag indicating whether the server is local, or not.
     - Note: The value is only valid after running the operation.
     */
    public var isLocal: Bool?

    init(parentName: String = #function,
         errorContainer: ServiceErrorProtocol = ErrorContainer(),
         serverName: String) {
        self.serverName = serverName
    }

    /**
     Looks up the given server name.
     - Returns: An array of IP addresses.
     */
    func lookupAddresses(serverName: String) -> [String] {
        var ipAddresses = [String]()
        let host = CFHostCreateWithName(
            nil, serverName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue()
            as NSArray?, success.boolValue {
            for case let theAddress as NSData in addresses {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self),
                               socklen_t(theAddress.length),
                               &hostname, socklen_t(hostname.count),
                               nil,
                               0, NI_NUMERICHOST) == 0 {
                    ipAddresses.append(String(cString: hostname))
                }
            }
        }
        return ipAddresses
    }

    override func main() {
        let queue = DispatchQueue.global()
        queue.async { [weak self] in
            if let theSelf = self {
                let _ = theSelf.lookupAddresses(serverName: theSelf.serverName)
            }
            self?.markAsFinished()
        }
    }
}
