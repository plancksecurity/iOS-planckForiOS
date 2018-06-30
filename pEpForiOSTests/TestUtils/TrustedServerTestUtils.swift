//
//  TrustedServerTestUtils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 29.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Server {
    @objc private var swizzledIsOnTrustedServer: Bool {
        return true
    }

    static private var originalMethod: Method {
        return class_getInstanceMethod(self, #selector(getter: trusted))!
    }

    static private var swizzledMethod: Method {
        return class_getInstanceMethod(self, #selector(getter: swizzledIsOnTrustedServer))!
    }

    public static func swizzleIsTrustedServerToAlwaysTrue() {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    //IOS-33: rethink if required.
    //    public static func unswizzleIsTrustedServer() {
    //        method_exchangeImplementations(swizzledMethod, originalMethod)
    //    }
}

//// MARK: - Force true isOnTrustedServer
////IOS-33: should be obsolete. Swizzel Server now.
//extension Message {
//    @objc private var swizzledIsOnTrustedServer: Bool {
//        return true
//    }
//
//    static private var originalMethod: Method {
//        return class_getInstanceMethod(self, #selector(getter: isOnTrustedServer))!
//    }
//
//    static private var swizzledMethod: Method {
//        return class_getInstanceMethod(self, #selector(getter: swizzledIsOnTrustedServer))!
//    }
//
//    public static func swizzleIsTrustedServerToAlwaysTrue() {
//        method_exchangeImplementations(originalMethod, swizzledMethod)
//    }
//
//    //IOS-33: rethink if required.
//    //    public static func unswizzleIsTrustedServer() {
//    //        method_exchangeImplementations(swizzledMethod, originalMethod)
//    //    }
//}
