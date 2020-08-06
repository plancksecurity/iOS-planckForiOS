//
//  VirtualFolder.swift
//  pEp
//
//  Created by Xavier Algarra on 02/04/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


public protocol VirtualFolderProtocol: DisplayableFolderProtocol {

    var agregatedFolderType : FolderType? { get }
    var countUnread : Int { get }
}

public extension VirtualFolderProtocol {
    var isSelectable: Bool {
        get {
            return true
        }
    }
}
