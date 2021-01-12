//
//  FolderInfo.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

struct FolderInfo {
    let name: String
    let folderType: FolderType
    let firstUID: UInt?
    let lastUID: UInt?
    let folderID: NSManagedObjectID?
}
