//
//  EnterpriseSettingsProtocol.swift
//  pEpForiOS
//
//  Created by Martín Brude on 19/1/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol EnterpriseSettingsProtocol {

    /// Indicates if the build is for enterprise
    var isEnterprise: Bool { get }
}
