//
//  Folder+pEp.swift
//  pEp
//
//  Created by Andreas Buff on 12.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Folder{

    /// Returns the first message found in this folder, that is marked for uidExpunge
    ///
    /// - Returns: the firsst message found that is marked for uidExpunge if any, nil otherwize
    public func firstMessageMarkedForUidExpunge() -> Message? {
        let predicateBelongingAccount =
            CdMessage.PredicateFactory.belongingToAccountWithAddress(address: account.user.address)
        let predicateParentFolder =
            CdMessage.PredicateFactory.belongingToParentFolderNamed(parentFolderName: name)
        let predicateMarkedUidExpunge = CdMessage.PredicateFactory.markedForUidMoveToTrash()
        let predicates = [predicateBelongingAccount,
                          predicateParentFolder,
                          predicateMarkedUidExpunge]
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let cdMessage = CdMessage.first(predicate: compoundPredicate)

        return cdMessage?.message()
    }
}
