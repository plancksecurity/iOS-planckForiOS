//
//  CdImapFields+Clone.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdImapFields {

    /// Clones this object.
    ///
    /// - note: The mandatory relationship to parent `message` is *not* copied.
    ///
    /// - Parameters:
    ///   - context: context to work on
    ///   - deleteOriginal: if true, this object AND the cloned imap flags are deleted
    /// - Returns: new imap fields with flags cloned from this object
    func clone(context: NSManagedObjectContext, deleteOriginal: Bool = false) -> CdImapFields {
        let fields = CdImapFields(context: context)

        fields.contentType = contentType
        fields.messageNumber = messageNumber
        fields.mimeBoundary = mimeBoundary

        fields.localFlags = localFlags?.clone(context: context, deleteOriginal: deleteOriginal)
        fields.serverFlags = serverFlags?.clone(context: context, deleteOriginal: deleteOriginal)
        if deleteOriginal {
            context.delete(self)
        }

        return fields
    }
}
