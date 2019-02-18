//
//  ReachibilityUtilsProtocol.swift
//  pEp
//
//  Created by Alejandro Gelos on 14/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ReachabilityUtilsProtocol {
    var delegate: ReachabilityDelegate? {get set}
    
    /// Get current connection status
    ///
    /// - Parameters:
    ///   - completion: connected and not connected to internet
    ///   - failure: failToGetReachabilityState when failed to get internet status
    func getConnectionStatus(completion: @escaping ((Reachability.Connection)->()),
                                failure: @escaping ((Reachability.ReachabilityError) -> ()) )
    
    /// Start updating internet connection state through ReachabilityDelegate
    func startNotifier()
    
    /// Stop updating reachable value
    func stopNotifier()
}
