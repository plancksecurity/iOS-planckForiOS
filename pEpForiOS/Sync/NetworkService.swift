//
//  NetworkService.swift
//  pEpForiOS
//
//  Created by hernani on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol INetworkService {
    func start()
}

/**
 * A class which provides an OO layer and doing syncing between CoreData and Pantomime
 * and any other (later) libraries providing in- and outbond transports of messages.
 */
public class NetworkService: INetworkService {
    let comp = "NetworkBackgroundService"
    let backgroundQueue: DispatchQueue!
    
    var connections: [Connection]?
    
    public init() {
        // Swift 3 GCD way according to http://swiftable.io/2016/06/dispatch-queues-swift-3/
        backgroundQueue = DispatchQueue(label: "pep.app.network.service",
                                      qos: .background,
                                      target: nil)
    }
    
    public func start() {
    }
    
    public func isBackgroundQueueExistent() -> Bool {
        if backgroundQueue != nil {
            return true
        }
        // default
        return false
    }
    
    /*!
     * @brief Accepts and executes code to the background.
     * @param workItem An object with code to be executed.
     * @param sync Optional argument to be set only to true if the code is to be
     * executed in synchronous way. Otherwise asynchronous execution occurs.
     */
    public func doWork(workItem: DispatchWorkItem, sync: Bool? = false) {
        if (sync == false) {
            backgroundQueue.async(execute: workItem)
        }
        else {
            backgroundQueue.sync(execute: workItem)
        }
    }
    
}
