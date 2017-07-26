//
//  EmailService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

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

    public init(connectInfo: EmailConnectInfo) {
        CWLogger.setLogger(Log.shared)

        self.connectInfo = connectInfo

        service = self.createService()
        service.setDelegate(self)
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

    open func cancel() {
        service.cancelRequest()
    }

    open func dumpMethodName(_ methodName: String, notification: Notification?) {
        // rm certain keys that are too long for logging
        var notificationCopy = notification
        if let dict = notification?.userInfo {
            var dictCopy = dict
            for k in ["NSDataToAppend", "NSData"] {
                if let data = dictCopy[k] as? NSData {
                    dictCopy[k] = "NSData with \(data.length) bytes"
                }
            }
            notificationCopy?.userInfo = dictCopy
        }
        Log.info(component: comp, content: "\(methodName): \(String(describing: notificationCopy))")
    }
}
