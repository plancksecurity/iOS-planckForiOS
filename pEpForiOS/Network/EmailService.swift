//
//  EmailService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol IEmailService {
    func start()
}

/**
 Base class for IMAP and SMTP implementations.
 */
open class Service: IEmailService {
    open var comp: String { get { return "Service" } }

    open let ErrorAuthenticationFailed = 10
    open let ErrorConnectionTimedOut = 1001

    let connectInfo: EmailConnectInfo

    var service: CWService!

    /**
     For proving memory leaks.
     */
    static open var refCounter = ReferenceCounter.init()

    /**
     Unnecessary data to trigger memory leak indicators.
     */
    var memoryLeakData: Data?

    public init(connectInfo: EmailConnectInfo) {
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

    open func start() {
        self.service.connectInBackgroundAndNotify()
    }

    open func bestAuthMethodFromList(_ mechanisms: [String])  -> AuthMethod {
        if mechanisms.count > 0 {
            let mechanismsLC = mechanisms.map() { mech in
                return mech.lowercased()
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

    open func bestAuthMethod()  -> AuthMethod {
        return bestAuthMethodFromList(service.supportedMechanisms() as! [String])
    }

    open func close() {
        service.close()
        service.setDelegate(nil)
    }

    open func dumpMethodName(_ methodName: String, notification: Notification?) {
        Log.infoComponent(comp, "\(methodName): \(notification)")
    }
}
