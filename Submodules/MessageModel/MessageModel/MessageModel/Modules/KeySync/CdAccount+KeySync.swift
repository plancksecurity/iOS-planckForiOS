//
//  CdAccount+KeySync.swift
//  MessageModel
//
//  Created by Andreas Buff on 18.11.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PEPObjCAdapterFramework
import pEpIOSToolbox

extension CdAccount {
    
    func isKeySyncEnabled(errorCallback: @escaping (Error) -> (),
                          successCallback: @escaping (Bool) -> ()) {
        guard let user = identity else {
            Log.shared.errorAndCrash("No identity")
            successCallback(false)
            return
        }
        PEPSession().queryKeySyncEnabled(for: user.pEpIdentity(),
                                              errorCallback: errorCallback,
                                              successCallback: successCallback)
    }

    func setKeySyncEnabled(enable: Bool,
                           errorCallback: @escaping (Error?) -> (),
                           successCallback: @escaping () -> ()) {
        guard let user = identity  else {
            Log.shared.errorAndCrash("Invalid account")
            errorCallback(nil)
            return
        }
        if enable {
            PEPSession().enableSync(for: user.pEpIdentity(),
                                         errorCallback: { error in
                                            errorCallback(error)
            }) {
                successCallback()
            }
        } else {
            PEPSession().disableSync(for: user.pEpIdentity(),
                                          errorCallback: { error in
                                            errorCallback(error)
            }) {
                successCallback()
            }
        }
    }
}
