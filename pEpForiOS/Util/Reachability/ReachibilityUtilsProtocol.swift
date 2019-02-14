//
//  ReachibilityUtilsProtocol.swift
//  pEp
//
//  Created by Alejandro Gelos on 14/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ReachibilityUtilsProtocol {
    var delegate: ReachabilityDelegate?    {get set}
    
    /// Get current connection status
    ///
    /// - Returns: Connection enum with none for no internet connection otherwise connected
    /// - Throws: failToGetReachabilityState when failed to get current internet state
    func getConnectionStatus() throws -> Reachability.Connection
    
    /// Start updateing internet conection state value.
    ///
    /// - Throws: failToGetReachabilityState when failed to start notifying current state
    func startNotifier() throws
    
    /// Stop updating internet connection value
    func stopNotifier()
}
