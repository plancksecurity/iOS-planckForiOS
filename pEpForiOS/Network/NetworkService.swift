//
//  NetworkService.swift
//  pEpForiOS
//
//  Created by hernani on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

protocol INetworkService {
}

/**
 * A RunLoop class which provides an OO layer and doing syncing between CoreData and Pantomime
 * and any other (later) libraries providing in- and outbond transports of messages.
 */
public class NetworkService: RunLoop, INetworkService {
    let comp = "NetworkService"
    let backgroundQueue = DispatchQueue(label: "pep.app.network.service", qos: .background,
                                                                         target: nil)
    var connectInfos = [ConnectInfo]()
    
    /*!
     * @brief Initialization of the Network Service for one connection.
     * @param connectInfo Single connection information (e. g. an IMAP server).
     */
    public init(connectInfo: ConnectInfo) {
        connectInfos.append(connectInfo)
    }
    
    /*!
     * @brief Initialization of Network Service for several connections.
     * @param connectInfos Array for multiple connection informations (e. g. several IMAP servers).
     */
    public init(connectInfos: [ConnectInfo]) {
        self.connectInfos = connectInfos
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
    
