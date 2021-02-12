//
//  UnifiedTrash.swift
//  pEp
//
//  Created by Martin Brude on 30/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class UnifiedTrash : UnifiedFolderBase {
    public override var agregatedFolderType: FolderType? {
        return FolderType.trash
    }
    public override var name: String {
        return NSLocalizedString("Trash (all)", comment: "Unified Trash Folder name")
    }
}
