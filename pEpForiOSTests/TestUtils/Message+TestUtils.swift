//
//  Message+TestUtils.swift
//  pEpForiOS
//
//  Created by buff on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

@testable import MessageModel
import CoreData
@testable import pEpForiOS
import PEPObjCAdapterFramework

extension Message {
    func isValidMessage() -> Bool {
        return self.longMessage != nil
            || self.longMessageFormatted != nil
            || self.attachments.count > 0
            || self.shortMessage != nil
    }

    public static func by(uid: Int,
                          folderName: String,
                          accountAddress: String,
                          context: NSManagedObjectContext) -> Message? {
        let pAccount =
            CdMessage.PredicateFactory.belongingToAccountWithAddress(address: accountAddress)
        let pUid = NSPredicate(format: "%K = %d", CdMessage.AttributeName.uid, uid)
        let pFolder =
            CdMessage.PredicateFactory.belongingToParentFolderNamed(parentFolderName: folderName)
        let p = NSCompoundPredicate(andPredicateWithSubpredicates: [pAccount, pUid, pFolder])
        guard let cdMessage = CdMessage.all(predicate: p, in: context)?.first as? CdMessage else {
            return nil
        }
        return MessageModelObjectUtils.getMessage(fromCdMessage: cdMessage)
    }
}
