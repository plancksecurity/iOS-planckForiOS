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

    public func bestAuthMethodFromList(mechanisms: [String])  -> AuthMethod {
        if mechanisms.count > 0 {
            let mechanismsLC = mechanisms.map() { mech in
                return mech.lowercaseString
            }
            let s = Set.init(mechanismsLC)
            if s.contains("cram-md5") {
                return .CramMD5
            }
            return .Login
        } else {
            return .Login
        }
    }

    public func bestAuthMethod()  -> AuthMethod {
        return bestAuthMethodFromList(service.supportedMechanisms() as! [String])
    }
}