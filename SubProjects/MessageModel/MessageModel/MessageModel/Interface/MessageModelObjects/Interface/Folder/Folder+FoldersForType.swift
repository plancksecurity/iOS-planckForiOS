//
//  Folder+FoldersForType.swift
//  MessageModel
//
//  Created by Xavier Algarra on 03/04/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension Folder {
    public static var planckSuspiciousFolderName: String {
        CdFolder.planckSuspiciousFolderName
    }
    
    public func update(folderType: FolderType) {
        guard let cdFolder = cdFolder() else {
            return
        }
        guard let account = cdFolder.account else {
            return
        }
        guard let moc = account.managedObjectContext else {
            return
        }
        moc.performAndWait {
            cdFolder.folderType = folderType
        }
        moc.saveAndLogErrors()
    }
    
    public static func getSuspiciousFolder(account: Account) -> Folder? {
        if let folder = Folder.by(account: account, folderType: .suspicious) {
            return folder
        }
        //For some unknown reason, sometimes 
        let normal = getAll(folderType: .normal)
        let suspicious = normal.first(where: {$0.realName == planckSuspiciousFolderName})
        suspicious?.update(folderType: .suspicious)
        return suspicious
    }

    public static func getAll(folderType: FolderType, session: Session = Session.main) -> [Folder]{
        let predicate = CdFolder.PredicateFactory.predicateForFolder(ofType: folderType)
        let cdFolders: [CdFolder] = CdFolder.all(predicate: predicate, in: session.moc) ?? []
        return cdFolders.map { $0.folder() }
    }

    /// Count unread emails on a folder type.
    /// - Parameters:
    ///   - foldersOfType: The folder type to filter
    ///   - session: The current session, if not specified will be `main`
    ///   - isUnified: Indicates if the predicate should count for the unified folder or not.
    /// - Returns: The number of unread mails for a certain folder type.
    public static func countUnreadIn(foldersOfType: FolderType, session: Session = Session.main, isUnified: Bool = false) -> Int {
        var predicates = [NSPredicate]()
        if isUnified {
            predicates.append(CdMessage.PredicateFactory.inUnifiedFolder())
        }
        predicates.append(CdMessage.PredicateFactory.existingMessages())
        predicates.append(CdMessage.PredicateFactory.processed())
        predicates.append(CdMessage.PredicateFactory.unread(value: true))
        predicates.append(CdMessage.PredicateFactory.isNotAutoConsumable())
        predicates.append(CdMessage.PredicateFactory.isIn(folderOfType: foldersOfType))
        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return CdMessage.count(predicate: comp, in: session.moc)
    }
}
