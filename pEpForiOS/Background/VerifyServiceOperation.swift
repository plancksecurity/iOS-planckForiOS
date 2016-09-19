//
//  VerifyServiceOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class VerifyServiceOperation: ConcurrentBaseOperation {
    var service: Service!
    let connectInfo: ConnectInfo
    let connectionManager: ConnectionManager

    /**
     Flag that the connection has already been finished, and was probably closed on request,
     so any errors like "connection lost" after that are ignored.
     This avoids the case where all went fine, then the
     connection is closed, and some "connection lost" or similar is sent to the delegate,
     and it sets an error.
     */
    var isFinishing: Bool = false

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        self.connectionManager = grandOperator.connectionManager
        super.init(coreDataUtil: grandOperator.coreDataUtil)
    }

    func close(finish: Bool) {
        service.close()
        if finish {
            markAsFinished()
        }
    }
}