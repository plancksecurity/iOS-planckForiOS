//
//  PEPDecryptFlags+ReUpload.swift
//  MessageModel
//
//  Created by Andreas Buff on 16.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

// MARK: - PEPDecryptFlags+ReUpload.swift

extension PEPDecryptFlags {

    var needsReupload: Bool {
        return flagIsSet(flag: .sourceModified)
    }

    func flagIsSet(flag: PEPDecryptFlags) -> Bool {
        switch flag {
        case .consume:
            return (self.rawValue & PEPDecryptFlags.consume.rawValue) > 0
        case .none:
            return (self.rawValue & PEPDecryptFlags.none.rawValue) > 0
        case .ignore:
            return (self.rawValue & PEPDecryptFlags.ignore.rawValue) > 0
        case .sourceModified:
            return (self.rawValue & PEPDecryptFlags.sourceModified.rawValue) > 0
        case .untrustedServer:
            return (self.rawValue & PEPDecryptFlags.untrustedServer.rawValue) > 0
        case .ownPrivateKey:
            return (self.rawValue & PEPDecryptFlags.ownPrivateKey.rawValue) > 0
        case .dontTriggerSync:
            return (self.rawValue & PEPDecryptFlags.dontTriggerSync.rawValue) > 0
        }
    }
}
