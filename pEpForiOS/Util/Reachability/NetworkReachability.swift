//
//  NetworkReachability.swift
//  pEp
//
//  Created by Alejandro Gelos on 13/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import SystemConfiguration

public class NetworkReachability: NetworkReachabilityProtocol {
    public init(){}
    
    public func networkReachabilityCreateWithName(_ allocator: CFAllocator?, _ nodename: UnsafePointer<Int8>) -> SCNetworkReachability? {
        return SCNetworkReachabilityCreateWithName(allocator, nodename)
    }
    
    public func networkReachabilityCreateWithAddress(_ allocator: CFAllocator?, _ address: UnsafePointer<sockaddr>) -> SCNetworkReachability? {
        return SCNetworkReachabilityCreateWithAddress(allocator, address)
    }
    
    public func networkReachabilityGetFlags(_ target: SCNetworkReachability, _ flags: UnsafeMutablePointer<SCNetworkReachabilityFlags>) -> Bool {
        return SCNetworkReachabilityGetFlags(target, flags)
    }
    
    @discardableResult public func networkReachabilitySetCallback(_ target: SCNetworkReachability, _ callout: SCNetworkReachabilityCallBack?, _ context: UnsafeMutablePointer<SCNetworkReachabilityContext>?) -> Bool {
        return SCNetworkReachabilitySetCallback(target, callout, context)
    }
}
