//
//  NetworkBackgroundService.swift
//  pEpForiOS
//
//  Created by hernani on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 * A class which provides an OO layer and doing syncing between CoreData and Pantomime
 * and any other (later) libraries providing in- and outbond transports of messages.
 */
public class NetworkBackgroundService {
    let comp = "NetworkBackgroundService"
    let backgroundQueue: DispatchQueue!
    
    public init() {
        // Swift 3 GCD way according to http://swiftable.io/2016/06/dispatch-queues-swift-3/
        backgroundQueue = DispatchQueue(label: "com.app.queue",
                                      qos: .background,
                                      target: nil)
    }
    
    // Method to query if background queue actually exists.
    public func isBackgroundQueueExistent() -> Bool {
        if backgroundQueue != nil {
            return true
        }
        // default
        return false
    }
    
}
