//
//  CWInternetAddress+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension CWInternetAddress {
    func identity(userID: String?) -> Identity {
        return Identity.create(address: address(), userID: userID,
                               userName: personal()?.fullyUnquoted())
    }
}
