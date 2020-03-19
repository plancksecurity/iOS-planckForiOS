//
//  Folder+FoldersForType.swift
//  MessageModel
//
//  Created by Xavier Algarra on 03/04/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Folder {

    public static func getAll(folderType: FolderType, session: Session = Session.main) -> [Folder]{
        let predicate = CdFolder.PredicateFactory.predicateForFolder(ofType: folderType)
        let cdFolders: [CdFolder] = CdFolder.all(predicate: predicate, in: session.moc) ?? []
        return cdFolders.map { $0.folder() }
    }
}
