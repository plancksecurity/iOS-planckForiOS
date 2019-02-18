//
//  ReachibilityUtilsProtocol.swift
//  pEp
//
//  Created by Alejandro Gelos on 14/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol ReachibilityUtilsProtocol {
    var delegate: ReachabilityDelegate? {get set}
    
    /// Get current connection status
    ///
    /// - Parameters:
    ///   - completion: Connection enum with notConnected for no internet connection otherwise connected
    ///   - failure: failToGetReachabilityState when failed to get current internet flags state
    func getConnectionStatus(completion: @escaping ((Reachability.Connection)->()),
                                failure: @escaping ((Reachability.ReachabilityError) -> ()) )
    
    /// Check if current connection is local or not.
    ///
    /// - Parameters:
    ///   - completion: true is connection is local, false otherwise
    ///   - failure: failToGetReachabilityState when failed to get current internet flags state
    func isLocal(completion: @escaping ((Bool)->()),
                    failure: @escaping ((Reachability.ReachabilityError) -> ()) )
    
    /// /// Start updateing internet conection state value through ReachabilityDelegate
    func startNotifier()
    
    /// Stop updating internet connection value
    func stopNotifier()
}
