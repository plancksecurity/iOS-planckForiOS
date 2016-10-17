//
//  CdFolder+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public extension CdFolder {
    /**
     Extracts a unique String ID that you can use as a key in dictionaries.
     - Returns: A (hashable) String that is unique for each folder.
     */
    public func hashableID() -> String {
        return "\(folderType.intValue) \(name) \(account.email)"
    }
}
