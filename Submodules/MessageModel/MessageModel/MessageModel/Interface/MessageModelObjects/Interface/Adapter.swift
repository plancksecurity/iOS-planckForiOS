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
    public static func leaveDeviceGroup(_ errorCallback: @escaping (Error) -> Void,
                                        successCallback: @escaping () -> Void) {
        PEPAsyncSession().leaveDeviceGroup(errorCallback, successCallback: successCallback)
    }
}
