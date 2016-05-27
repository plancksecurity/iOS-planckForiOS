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

    /**
     For proving memory leaks.
     */
    public var refCounter: ReferenceCounter?

    let connectInfo: ConnectInfo

    var service: CWService!
    let blowupData: NSData

    public init(connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo

        let s: NSMutableString = ""
        for _ in 1...10000 {
            s.appendString("This is way too much!")
        }
        let someData = NSMutableData.init()
        for _ in 1...100 {
            someData.appendData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        blowupData = NSData.init(data: someData)

        service = self.createService()
        service.setDelegate(self)
        service.setLogger(Log())
    }

    deinit {
        service.close()
        refCounter?.dec()
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
}