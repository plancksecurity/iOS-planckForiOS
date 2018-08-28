//
//  Folder+Imap.swift
//  pEp
//
//  Created by Andreas Buff on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

//IOS-729: seperate concerns (threading, imap ...)
import MessageModel

/// Logic based on data MessageModel should not know.
extension Folder {

    public func indexOf(message: Message) -> Int? {
        let i2 = indexOfBinary(message: message)
        return i2
    }

//    /**
//     - Returns: All the messages contained in that folder in a flat and linear way,
//     that is no threading involved.
//     */
//    open func allCdMessagesNonThreaded(includingDeleted: Bool = false,
//                                       includingMarkedForMoveToFolder: Bool = false) -> [CdMessage] {
//        var predicates = [NSPredicate]()
//
//        if let cdFolder = cdFolder() {
//            predicates.append(containedMessagesPredicate(cdFolder: cdFolder))
//        }
//
//        return allCdMessages(includingDeleted: includingDeleted,
//                             includingMarkedForMoveToFolder: includingMarkedForMoveToFolder,
//                             takingPredicatesIntoAccount: predicates)
//    }

    /**
     - Returns: All the messages contained in that folder in a flat and linear way,
     that is no threading involved.
     */
    public func allMessagesNonThreaded() -> [Message] {
        return allCdMessagesNonThreaded().compactMap {
            return $0.message()
        }
    }

    public func messageAt(index: Int) -> Message? {
        if let cdMessage = allCdMessagesNonThreaded()[safe: index] {
            return cdMessage.message()
        }
        return nil
    }

//    public func messageCount() -> Int {
//        return allCdMessagesNonThreaded().count
//    }

//    func defaultSortDescriptors() -> [NSSortDescriptor] {
//        return [NSSortDescriptor(key: "sent", ascending: false),
//                NSSortDescriptor(key: "uid", ascending: false),
//                NSSortDescriptor(key: "parent.name", ascending: false)]
//    }

//    public func allCdMessages(includingDeleted: Bool, includingMarkedForMoveToFolder: Bool = false,
//                              takingPredicatesIntoAccount prePredicates: [NSPredicate])  -> [CdMessage] {
//        var predicates = prePredicates
//
//        predicates.append(CdMessage.PredicateFactory.decrypted())
//        if !includingDeleted {
//            predicates.append(CdMessage.PredicateFactory.undeleted())
//        }
//        if !includingMarkedForMoveToFolder {
//            predicates.append(CdMessage.PredicateFactory.notMarkedForMoveToFolder())
//        }
//        if let filterPredicates = filter?.predicates {
//            predicates.append(contentsOf: filterPredicates)
//        }
//        let p = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
//        let descs = defaultSortDescriptors()
//        let msgs = CdMessage.all(predicate: p, orderedBy: descs) as? [CdMessage] ?? []
//        return msgs
//    }

//    open func contains(message: Message, deletedMessagesAreContained: Bool = false,
//                       markedForMoveToFolderArteContained: Bool = false) -> Bool {
//        if let cdFolder = cdFolder() {
//            var ps = [NSPredicate]()
//            ps.append(containedMessagesPredicate(cdFolder: cdFolder))
//            if deletedMessagesAreContained {
//                ps.append(NSPredicate(format: "uuid = %@", message.uuid))
//                if let account = CdAccount.search(account: message.parent.account) {
//                    ps.append(NSPredicate(format: "parent.account = %@", account))
//                }
//            }
//            if !markedForMoveToFolderArteContained {
//                ps.append(CdMessage.PredicateFactory.notMarkedForMoveToFolder())
//            }
//            let p = NSCompoundPredicate(andPredicateWithSubpredicates: ps)
//            let d = defaultSortDescriptors()
//            if let _ = CdMessage.first(predicate: p, orderedBy: d) {
//                return true
//            }
//        }
//        return false
//    }

    func indexOfBinary(message: Message) -> Int? {
        func comparator(m1: CdMessage, m2: CdMessage) -> ComparisonResult {
            for desc in defaultSortDescriptors() {
                let c1 = desc.compare(m1, to: m2)
                if c1 != .orderedSame {
                    return c1
                }
            }
            return .orderedSame
        }

        guard let cdMsg = CdMessage.search(message: message) else {
            return nil
        }
        let msgs = allCdMessagesNonThreaded()
        return msgs.binarySearch(element: cdMsg, comparator: comparator)
    }
}
