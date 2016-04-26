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

    let ErrorAuthenticationFailed = 1000
    let ErrorConnectionTimedOut = 1001

    let connectInfo: ConnectInfo
    let coreDataUtil: CoreDataUtil

    private var testOnlyCallback: (NSError? -> ())? = nil

    var isJustATest: Bool {
        get {
            return testOnlyCallback != nil
        }
    }

    var service: CWService!

    init(coreDataUtil: CoreDataUtil, connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        self.coreDataUtil = coreDataUtil
        service = self.createService()
        service.setDelegate(self)
        service.setLogger(Log())
    }

    func createService() -> CWService {
        // This must be overridden!
        abort()
    }

    func start() {
        dispatch_async(dispatch_get_main_queue(), {
            self.service.connectInBackgroundAndNotify()
        })
    }

    func test(block:(NSError? -> ())) {
        testOnlyCallback = block
        service.connectInBackgroundAndNotify()
    }

    /**
     If this was just a test, invoke the test block with that error.

     - Returns: `true` if this was indeed only a test, `false` otherwise.
     */
    func callTestBlock(error: NSError?) -> Bool {
        if let block = testOnlyCallback {
            block(error)
            return true
        }
        return false
    }

    deinit {
        service.close()
    }
}