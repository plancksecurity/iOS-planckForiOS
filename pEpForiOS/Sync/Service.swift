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
    public var comp: String { get { return "Service" } }

    public let ErrorAuthenticationFailed = 10
    public let ErrorConnectionTimedOut = 1001

    let connectInfo: ConnectInfo

    var service: CWService!

    /**
     For proving memory leaks.
     */
    static public var refCounter = ReferenceCounter.init()

    /**
     Unnecessary data to trigger memory leak indicators.
     */
    var memoryLeakData: NSData?

    public init(connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo

        service = self.createService()
        service.setDelegate(self)
        service.setLogger(Log())
        Service.refCounter.inc()
    }

    deinit {
        service.close()
        Service.refCounter.dec()
    }

    func createService() -> CWService {
        // This must be overridden!
        abort()
    }

    public func start() {
        self.service.connectInBackgroundAndNotify()
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

    public func close() {
        service.close()
        service.setDelegate(nil)
    }

    public func dumpMethodName(methodName: String, notification: NSNotification?) {
        Log.infoComponent(comp, "\(methodName): \(notification)")
    }
}