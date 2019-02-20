//
//  NetworkReachability.swift
//  pEp
//
//  Created by Alejandro Gelos on 13/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import SystemConfiguration

class NetworkReachability: NetworkReachabilityProtocol {
    init(){}
    
    func networkReachabilityGetFlags(_ target: SCNetworkReachability, _ flags: UnsafeMutablePointer<SCNetworkReachabilityFlags>) -> Bool {
        return SCNetworkReachabilityGetFlags(target, flags)
    }
    
    @discardableResult func networkReachabilitySetCallback(_ target: SCNetworkReachability, _ callout: SCNetworkReachabilityCallBack?, _ context: UnsafeMutablePointer<SCNetworkReachabilityContext>?) -> Bool {
        return SCNetworkReachabilitySetCallback(target, callout, context)
    }
}
