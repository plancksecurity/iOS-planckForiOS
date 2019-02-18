//
//  ReachibilityUtilsProtocol.swift
//  pEp
//
//  Created by Alejandro Gelos on 14/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ReachibilityUtilsProtocol {
    var delegate: ReachabilityDelegate? {get set}
    
    /// Get current connection status
    ///
    /// - Parameters:
    ///   - completion: reachable and not reachable to spefify host.
    ///   - failure: failToGetReachabilityState when failed to get current internet flags state
    func getConnectionStatus(completion: @escaping ((Reachability.Connection)->()),
                                failure: @escaping ((Reachability.ReachabilityError) -> ()) )
    
    /// Check if current connection is local or not.
    ///
    /// - Parameters:
    ///   - completion: true if specify host is a localhost, otherwise false
    ///   - failure: failToGetReachabilityState when failed to get current internet flags state
    func isLocal(completion: @escaping ((Bool)->()),
                    failure: @escaping ((Reachability.ReachabilityError) -> ()) )
    
    /// Start updateing reachable state value through ReachabilityDelegate
    func startNotifier()
    
    /// Stop updating reachable value
    func stopNotifier()
}
