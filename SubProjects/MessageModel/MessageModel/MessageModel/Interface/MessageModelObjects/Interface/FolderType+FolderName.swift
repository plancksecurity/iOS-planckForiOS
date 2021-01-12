//
//  Folder+FolderName.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.11.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension FolderType {
    /// Each kind has a human-readable name you can use to create a local folder object.
    /// - Note: This is used *only* for the local-only special folders, and for fuzzy-matching
    ///         against a known folder type when fetching from the remote server.
    public func folderName() -> String {
        return folderNames()[0]
    }
}
