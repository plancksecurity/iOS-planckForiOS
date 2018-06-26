//
//  Message+TestUtils.swift
//  pEpForiOS
//
//  Created by buff on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    func isValidMessage() -> Bool {
        return self.longMessage != nil
            || self.longMessageFormatted != nil
            || self.attachments.count > 0
            || self.shortMessage != nil
    }

    static public func fakeMessage(uuid: MessageID) -> Message {
        // miss use unifiedInbox() to create fake folder
        let fakeFolder = UnifiedInbox()
        fakeFolder.filter = nil

        return Message(uuid: uuid, parentFolder: fakeFolder)
    }
}

// MARK: - Force true isOnTrustedServer

extension Message {
    @objc private var swizzledIsOnTrustedServer: Bool {
        return true
    }

    static private var originalMethod: Method {
        return class_getInstanceMethod(self, #selector(getter: isOnTrustedServer))!
    }

    static private var swizzledMethod: Method {
        return class_getInstanceMethod(self, #selector(getter: swizzledIsOnTrustedServer))!
    }
    
    public static func swizzleIsTrustedServerToAlwaysTrue() {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    public static func unswizzleIsTrustedServerToDefault() {
        method_exchangeImplementations(swizzledMethod, originalMethod)
    }
}
