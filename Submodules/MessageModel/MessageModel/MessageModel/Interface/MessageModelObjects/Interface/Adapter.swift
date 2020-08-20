//
//  Adapter.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

/// Wraps adapter functionality so the app doesn't have to deal with it directly.
public class Adapter {
    static public func leaveDeviceGroup(_ errorCallback: @escaping (Error) -> Void,
                                        successCallback: @escaping () -> Void) {
        PEPAsyncSession().leaveDeviceGroup(errorCallback, successCallback: successCallback)
    }

    static public func setUnEncryptedSubjectEnabled(_ enabled: Bool) {
        PEPObjCAdapter.setUnEncryptedSubjectEnabled(enabled)
    }

    static public func setPassiveModeEnabled(_ enabled: Bool) {
        PEPObjCAdapter.setPassiveModeEnabled(enabled)
    }

    static public func cleanup() {
        PEPSession.cleanup()
    }
}
