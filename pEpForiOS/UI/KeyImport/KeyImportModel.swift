//
//  KeyImportModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Model for importing keys from the filesystem, and setting them as own keys.
class KeyImportModel {
    public private(set) var rows = [Row]()
}

extension KeyImportModel {
    struct Row {
    }
}
