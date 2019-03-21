//
//  ReachabilityProtocol.swift
//  pEp
//
//  Created by Alejandro Gelos on 14/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

protocol ReachabilityProtocol {
    var delegate: ReachabilityDelegate? {get set}
    
    func getConnectionStatus(completion: @escaping ((Reachability.Connection)->()),
                                failure: @escaping ((Reachability.ReachabilityError) -> ()) )
    func startNotifier()
    func stopNotifier()
}
