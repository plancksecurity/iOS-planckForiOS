//
//  Array+Extension.swift
//  pEp
//
//  Created by Xavier Algarra on 13/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension Array where Element == Folder {

    public func sorted() -> [Folder] {
        return sorted { (first, second) -> Bool in
            guard let idx1 = FolderType.displayOrder.firstIndex(of: first.folderType),
                let idx2 = FolderType.displayOrder.firstIndex(of: second.folderType) else {
                    return false
            }
            return idx1 < idx2
        }
    }

}
