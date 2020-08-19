//
//  Adapter.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

public class Adapter {
    /// Wraps `PEPAsyncSession.leaveDeviceGroup`
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
}
