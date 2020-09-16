//
//  AppSettings+UsePEPFolderProvider.swift
//  pEp
//
//  Created by Andreas Buff on 25.06.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension AppSettings: UsePEPFolderProviderProtocol {
    public var usePepFolder: Bool {
        return usePEPFolderEnabled
    }
}
