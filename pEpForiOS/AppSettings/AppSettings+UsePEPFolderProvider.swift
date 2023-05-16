//
//  AppSettings+usePlanckFolderProvider.swift
//  pEp
//
//  Created by Andreas Buff on 25.06.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension AppSettings: UsePlanckFolderProviderProtocol {
    public var usePlanckFolder: Bool {
        return usePEPFolderEnabled
    }
}
