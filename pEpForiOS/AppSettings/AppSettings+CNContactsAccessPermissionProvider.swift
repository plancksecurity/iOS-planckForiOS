//
//  AppSettings+CNContactsAccessPermissionProvider.swift
//  pEp
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - CNContactsAccessPermissionProviderProtocol

extension AppSettings: CNContactsAccessPermissionProviderProtocol {
    // AppSettings fullfils all requirements of CNContactsAccessPermissionProviderProtocol already.
    // Nothing to do beside letting the world know that it does by conforming to it.
}
