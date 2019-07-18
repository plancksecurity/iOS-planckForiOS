//
//  Message+TestUtils.swift
//  pEpForiOS
//
//  Created by buff on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

@testable import MessageModel
@testable import pEpForiOS
import PEPObjCAdapterFramework

extension Message {
    func isValidMessage() -> Bool {
        return self.longMessage != nil
            || self.longMessageFormatted != nil
            || self.attachments.count > 0
            || self.shortMessage != nil
    }

    public func pEpMessageDict(outgoing: Bool = true) -> PEPMessageDict {
        var dict = PEPMessageDict()

        if let subject = shortMessage {
            dict[kPepShortMessage] = subject as NSString
        }

        if let text = longMessage {
            dict[kPepLongMessage] = text as NSString
        }

        if let text = longMessageFormatted {
            dict[kPepLongMessageFormatted] = text as NSString
        }

        dict[kPepTo] = NSArray(array: to.map() { return $0.pEpIdentity() })
        dict[kPepCC] = NSArray(array: cc.map() { return $0.pEpIdentity() })
        dict[kPepBCC] = NSArray(array: bcc.map() { return $0.pEpIdentity() })

        dict[kPepFrom]  = PEPUtils.pEpOptional(identity: from) as AnyObject
        dict[kPepID] = messageID as AnyObject
        dict[kPepOutgoing] = outgoing as AnyObject?

        dict[kPepAttachments] = NSArray(array: attachments.map() {
            return PEPUtils.pEpAttachment(attachment: $0)
        })

        return dict
    }

    public static func by(uid: Int, folderName: String, accountAddress: String) -> Message? {
        let pAccount =
            CdMessage.PredicateFactory.belongingToAccountWithAddress(address: accountAddress)
        let pUid = NSPredicate(format: "%K = %d", CdMessage.AttributeName.uid, uid)
        let pFolder =
            CdMessage.PredicateFactory.belongingToParentFolderNamed(parentFolderName: folderName)
        let p = NSCompoundPredicate(andPredicateWithSubpredicates: [pAccount, pUid, pFolder])
        guard let cdMessage = CdMessage.all(predicate: p)?.first as? CdMessage else {
            return nil
        }
        return MessageModelObjectUtils.getMessage(fromCdMessage: cdMessage)
    }
}
