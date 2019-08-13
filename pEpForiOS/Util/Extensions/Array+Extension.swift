//
//  Array+Extension.swift
//  pEp
//
//  Created by Xavier Algarra on 13/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension Array {

    public static func sort(foldersToSort: [Folder]) -> [Folder] {
        return foldersToSort.sorted { (first, second) -> Bool in
            guard let idx1 = FolderType.displayOrder.firstIndex(of: first.folderType),
                let idx2 = FolderType.displayOrder.firstIndex(of: second.folderType) else {
                    return false
            }
            return idx1 < idx2
        }
    }

}
