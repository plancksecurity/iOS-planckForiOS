//
//  NetworkReachabilityProtocol.swift
//  pEp
//
//  Created by Alejandro Gelos on 13/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import SystemConfiguration

protocol NetworkReachabilityProtocol: class {
    func networkReachabilityGetFlags(_ target: SCNetworkReachability, _ flags: UnsafeMutablePointer<SCNetworkReachabilityFlags>) -> Bool
    @discardableResult func networkReachabilitySetCallback(_ target: SCNetworkReachability, _ callout: SCNetworkReachabilityCallBack?, _ context: UnsafeMutablePointer<SCNetworkReachabilityContext>?) -> Bool
}
