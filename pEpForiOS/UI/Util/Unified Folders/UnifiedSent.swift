//
//  UnifiedSent.swift
//  pEp
//
//  Created by Martin Brude on 30/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class UnifiedSent : UnifiedFolderBase {
    public override var agregatedFolderType: FolderType? {
        return FolderType.sent
    }
    public override var name: String {
        return NSLocalizedString("Sent (all)", comment: "Unified Sent Folder name")
    }
}
