//
//  CdMessage+Fake.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCAdapterFramework
import pEpIOSToolbox

extension CdMessage {

    /// uid for Fake messages, that are created to show to the user until the actual, real message
    /// is fetched from server.
    /// Example:
    /// User deletes a mail and expects this mail to show up in trah folder imedeatelly. Thus we
    /// save a fake message to show to the user until the real message is fetched.
    static let uidFakeResponsivenes = -1

    /// Creates a clone with fake message UID.
    /// Does not save the context.
    @discardableResult public func createFakeMessage(context: NSManagedObjectContext) -> CdMessage {
        let fakeMsg = cloneWithZeroUID(context: context)
        fakeMsg.uid = Int32(CdMessage.uidFakeResponsivenes)
        fakeMsg.pEpRating = pEpRating

        return fakeMsg
    }

    /// This method is looking for a fake message with/in the given UUID, updates it's UID and
    /// deletes the real message.
    /// The previously faked message becomes the real message. This  way clients can keep on using
    /// the fake message without knowing about its existence
    ///
    /// -note:  The given `realMessage might be deleted. You MUST NOT use it any more after calling
    ///         this method. Use the returned message instead.
    ///
    /// - Parameters:
    ///   - uuid: uuid to identify the fake message with
    ///   - realMessage:    the message fetched from server.
    ///                     You MUST NOT use it any more after calling this method
    ///   - context: context safe to use the realMessage on
    /// - Returns:  if a fake message existed: the updated fake message
    ///             otherwize: the un-altered realMessage
    static func findAndUpdateFakeMessage(withUuid uuid: String,
                                         realMessage: CdMessage,
                                         context: NSManagedObjectContext) -> CdMessage {
        guard let parentFolder = realMessage.parent  else {
            if realMessage.isDeleted {
                Log.shared.error("No no parentFolder. The only known valid case is that the user has deleted the account and thus whiped all messages.")
            } else {
                Log.shared.errorAndCrash("No no parentFolder.")
            }
            return realMessage
        }
        guard let existingFakeMessage = existingFakeMessage(for: uuid,
                                                            in: parentFolder,
                                                            context: context)
            else {
                // No fake message exists, nothing to do.
                return realMessage
        }

        existingFakeMessage.uid = realMessage.uid
        existingFakeMessage.pEpRating = realMessage.pEpRating
        existingFakeMessage.keysFromDecryption = realMessage.keysFromDecryption
        context.delete(realMessage)

        return existingFakeMessage
    }

    static private func existingFakeMessage(for uuid: String,
                                            in folder: CdFolder,
                                            context: NSManagedObjectContext) -> CdMessage? {
        return CdMessage.search(uid: Int32(CdMessage.uidFakeResponsivenes),
                                uuid: uuid,
                                folderName: folder.nameOrCrash,
                                inAccount: folder.accountOrCrash,
                                context: context)
    }
}
