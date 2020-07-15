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
    ///   - session: The current session, if not specified will be `main`
    /// - Returns: The number of unread mails for a certain folder type.
    public static func countAllUnread(session: Session = Session.main) -> Int {
        var predicates = [NSPredicate]()
        predicates.append(CdMessage.PredicateFactory.existingMessages())
        predicates.append(CdMessage.PredicateFactory.processed())
        predicates.append(CdMessage.PredicateFactory.isNotAutoConsumable())
        predicates.append(CdMessage.PredicateFactory.unread(value: true))
        let compound = NSCompoundPredicate(type: .and, subpredicates: predicates)
        return CdMessage.count(predicate: compound, in: session.moc)
    }
}
