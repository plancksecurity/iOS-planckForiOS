//
//  Folder+Subfolders.swift
//  MessageModel
//
//  Created by Martín Brude on 2/2/21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation


extension Folder {

    /// - Returns: The all subfolders, recursively.    
    public func getSubfoldersRecursively<T: Folder>() -> [T] {
        var subfoldersToReturn = [T]()
        subFolders().forEach { subfolder in
            subfoldersToReturn += subfolder.getSubfoldersRecursively() as [T]
            if let subfolder = subfolder as? T {
                subfoldersToReturn.append(subfolder)
            }
        }
        return subfoldersToReturn
    }
}
