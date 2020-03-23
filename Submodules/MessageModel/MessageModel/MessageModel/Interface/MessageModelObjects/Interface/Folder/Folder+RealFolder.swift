//
//  Folder+RealFolder.swift
//  MessageModel
//
//  Created by Xavier Algarra on 10/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Folder: RealFolderProtocol  {

    /**
     Updates the lastLookedAt field with the current date and saves the folder
     */
    public func updateLastLookAt() {
        lastLookedAt = Date()
        save()
    }

}
