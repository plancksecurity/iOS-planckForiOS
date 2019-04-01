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

    static public func fakeMessage(uuid: MessageID) -> Message {
        // miss use unifiedInbox() to create fake folder
        let fakeFolder = UnifiedInbox()
        fakeFolder.filter = nil

        return Message(uuid: uuid, parentFolder: fakeFolder)
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

        dict[kPepTo] = NSArray(array: to.map() { return PEPUtil.pEp(identity: $0) })
        dict[kPepCC] = NSArray(array: cc.map() { return PEPUtil.pEp(identity: $0) })
        dict[kPepBCC] = NSArray(array: bcc.map() { return PEPUtil.pEp(identity: $0) })

        dict[kPepFrom]  = PEPUtil.pEpOptional(identity: from) as AnyObject
        dict[kPepID] = messageID as AnyObject
        dict[kPepOutgoing] = outgoing as AnyObject?

        dict[kPepAttachments] = NSArray(array: attachments.map() {
            return PEPUtil.pEpAttachment(attachment: $0)
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
        let cdMessage = CdMessage.all(predicate: p)?.first as? CdMessage
        return cdMessage?.message()
    }
}
