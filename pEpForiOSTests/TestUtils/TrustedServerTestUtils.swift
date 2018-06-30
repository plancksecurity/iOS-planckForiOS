//
//  TrustedServerTestUtils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 29.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

struct TrustedServerTestUtils {

//    static func swizzleIsTrustedServerToAlwaysTrue() {
//        Server.swizzleIsTrustedServerToAlwaysTrue()
//    }

    /**
     Validates all servers and their credentials without actually validating them.
     */
    static func setServersTrusted(forAccount account: Account, testCase: XCTestCase) {
        guard let servers = account.cdAccount()?.servers?.allObjects as? [CdServer] else {
            XCTFail("No Servers")
            return
        }
        for server in servers {
            server.trusted = true
        }
    }

}
//IOS-33: if obsolete, remove @objc's !!

//fileprivate extension Server {
//    @objc private var swizzledIsOnTrustedServer: Bool {
//        return true
//    }
//
//    static private var originalMethod: Method {
//        return class_getInstanceMethod(self, #selector(getter: trusted))!
//    }
//
//    static private var swizzledMethod: Method {
//        return class_getInstanceMethod(self, #selector(getter: swizzledIsOnTrustedServer))!
//    }
//
//    fileprivate static func swizzleIsTrustedServerToAlwaysTrue() {
//        method_exchangeImplementations(originalMethod, swizzledMethod)
//    }
//
//    //IOS-33: rethink if required.
//    //    public static func unswizzleIsTrustedServer() {
//    //        method_exchangeImplementations(swizzledMethod, originalMethod)
//    //    }
//}
