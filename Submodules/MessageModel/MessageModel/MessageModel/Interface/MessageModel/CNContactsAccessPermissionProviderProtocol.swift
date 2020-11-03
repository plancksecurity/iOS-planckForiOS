//
//  CNContactsAccessPermissionProviderProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

public protocol CNContactsAccessPermissionProviderProtocol {
    var userHasBeenAskedForContactAccessPermissions: Bool { get }
}

