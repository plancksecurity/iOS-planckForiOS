//
//  Service.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol IService {
    func start()
}

/**
 Base class for IMAP and SMTP implementations.
 */
public class Service: IService {

    public let ErrorAuthenticationFailed = 1000
    public let ErrorConnectionTimedOut = 1001

    let connectInfo: ConnectInfo

    var service: CWService!

    public init(connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        service = self.createService()
        service.setDelegate(self)
        service.setLogger(Log())
    }

    func createService() -> CWService {
        // This must be overridden!
        abort()
    }

    public func start() {
        dispatch_async(dispatch_get_main_queue(), {
            self.service.connectInBackgroundAndNotify()
        })
    }

    deinit {
        service.close()
    }
}