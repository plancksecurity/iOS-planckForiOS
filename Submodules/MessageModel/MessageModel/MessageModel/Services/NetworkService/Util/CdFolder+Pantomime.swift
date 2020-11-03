//
//  CdFolder+Pantomime.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework

extension CdFolder {
    func cwFolder() -> CWIMAPFolder? {
        if let theName = name {
            return CWIMAPFolder(name: theName)
        }
        return nil
    }
}
