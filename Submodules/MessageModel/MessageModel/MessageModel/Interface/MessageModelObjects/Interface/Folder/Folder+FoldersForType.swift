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

    /// Count unread emails on a folder type.
    /// - Parameters:
    ///   - folderType: The folder type to filter
    ///   - session: The current session, if not specified will be `main`
    /// - Returns: The number of unread mails for a certain folder type.
    public static func countAllUnread(folderType: FolderType, session: Session = Session.main) -> Int {
        var predicates = [NSPredicate]()
        predicates.append(Message.PredicateFactory.existingMessages())
        predicates.append(Message.PredicateFactory.processed())
        predicates.append(Message.PredicateFactory.unread(value: true))
        predicates.append(Message.PredicateFactory.isNotAutoConsumable())
        predicates.append(CdMessage.PredicateFactory.isIn(folderType: folderType))
        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return CdMessage.count(predicate: comp, in: session.moc)
    }
}
