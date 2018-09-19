//
//  AttachmentFilter.swift
//  MessageModel
//
//  Created by Xavier Algarra on 02/10/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import MessageModel

public class AttachmentFilter: FilterBase {
    public static let unviewableMimeTypes = Set([
        "application/pgp-keys",
        "application/pgp-signature"]
    )

    public override var predicates : [NSPredicate] {
        get {
            return [CdMessage.PredicateFactory.hasViewableAttachments()]
        }
    }

    public override var title: String {
        get {
            return NSLocalizedString("With attachments", comment: "Title for attachments filter")
        }
    }

    public override func fulfillsFilter(message: Message) -> Bool {
        let viewableAttachments = message.attachments.filter {
            !AttachmentFilter.unviewableMimeTypes.contains($0.mimeType.lowercased())
        }
        return viewableAttachments.count > 0
    }

    public override var hashValue: Int {
        get {
            return 31
        }
    }

    public override func isEqual(filter: FilterBase) -> Bool {
        if let _ = filter as? AttachmentFilter {
            return true
        }
        return false
    }
}
