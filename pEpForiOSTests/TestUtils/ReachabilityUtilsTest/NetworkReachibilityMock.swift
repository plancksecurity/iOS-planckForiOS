//
//  NetworkReachibilityMock.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 13/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
import SystemConfiguration
@testable import pEpForiOS


class YesInternetNetworkReachibilityMock: NetworkReachabilityProtocol {
    let callback: SCNetworkReachabilityCallBack = { (reachability, flags, info) in
        guard let info = info else { return }
        
        let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
        reachability.flags = [SCNetworkReachabilityFlags.reachable]
    }
    
    func networkReachabilityCreateWithName(_ allocator: CFAllocator?,
                                           _ nodename: UnsafePointer<Int8>)
        -> SCNetworkReachability? {
        return SCNetworkReachabilityCreateWithName(allocator, nodename)
    }
    
    func networkReachabilityGetFlags(_ target: SCNetworkReachability,
                                     _ flags: UnsafeMutablePointer<SCNetworkReachabilityFlags>)
        -> Bool {
        flags.pointee = [SCNetworkReachabilityFlags.reachable]
        return true
    }
    
    @discardableResult func networkReachabilitySetCallback(_ target: SCNetworkReachability,
                                                           _ callout: SCNetworkReachabilityCallBack?,
                                     _ context: UnsafeMutablePointer<SCNetworkReachabilityContext>?)
        -> Bool {
        return SCNetworkReachabilitySetCallback(target, callback, context)
    }
}

class NoInternetLocalNetworkReachibilityMock: NetworkReachabilityProtocol {
    let callback: SCNetworkReachabilityCallBack = { (reachability, flags, info) in
        guard let info = info else { return }
        
        let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
        reachability.flags = []
    }
    
    func networkReachabilityCreateWithName(_ allocator: CFAllocator?,
                                           _ nodename: UnsafePointer<Int8>)
        -> SCNetworkReachability? {
        return SCNetworkReachabilityCreateWithName(allocator, nodename)
    }
    
    func networkReachabilityGetFlags(_ target: SCNetworkReachability,
                                     _ flags: UnsafeMutablePointer<SCNetworkReachabilityFlags>)
        -> Bool {
        flags.pointee = [.isLocalAddress]
        return true
    }
    
    @discardableResult func networkReachabilitySetCallback(_ target: SCNetworkReachability, _ callout: SCNetworkReachabilityCallBack?, _ context: UnsafeMutablePointer<SCNetworkReachabilityContext>?)
        -> Bool {
        return SCNetworkReachabilitySetCallback(target, callback, context)
    }
}
