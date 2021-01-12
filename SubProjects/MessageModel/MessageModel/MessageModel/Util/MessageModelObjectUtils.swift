//
//  MessageModelObjectUtils.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 28/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

struct MessageModelObjectUtils {

    /// Creates a Message wrapping a given CdMessage.
    /// - note: By default (if no context is given) the message MUST be used on the main queue
    /// only. If you need to use the created Message on another queue, provide a suitable
    /// `context`.
    /// - Parameters:
    ///   - cdMessage: message to wrap
    ///   - context:    MOC suitable for the queue you want to use the returned Message on.
    ///                 Defaults the best suitable moc that can be found, which might lead to undefined behaviour.
    /// - Returns: Message wrapping given CdMessage
    static func getMessage(fromCdMessage cdObject: CdMessage,
                           context: NSManagedObjectContext? = nil) -> Message {
        let moc: NSManagedObjectContext =
            context ?? cdObject.managedObjectContext ??  Stack.shared.mainContext
        return Message(cdObject: cdObject, context: moc)
    }

    /// Creates an Attachment wrapping a given CdAttachment.
    /// - Parameters:
    ///   - cdMessage: message to wrap
    ///   - context:    MOC suitable for the queue you want to use the returned Message on.
    ///                 Defaults the best suitable moc that can be found, which might lead to undefined behaviour.
    /// - Returns: Attachment wrapping given CdAttachment
    static func getAttachment(fromCdAttachment cdObject: CdAttachment,
                              context: NSManagedObjectContext? = nil) -> Attachment {
        let moc: NSManagedObjectContext =
            context ?? cdObject.managedObjectContext ?? Stack.shared.mainContext
        return Attachment(cdObject: cdObject, context: moc)
    }

    /// Creates an MMO wrapping a given NSManagesObject.
    /// - Parameters:
    ///   - cdMessage: message to wrap
    ///   - context:    MOC suitable for the queue you want to use the returned Message on.
    ///                 Defaults the best suitable moc that can be found, which might lead to undefined behaviour.
    /// - Returns: MMO wrapping given NSManagedObject
    static func getAccount(fromCdAccount cdObject: CdAccount,
                              context: NSManagedObjectContext? = nil) -> Account {
        let moc: NSManagedObjectContext =
            context ?? cdObject.managedObjectContext ?? Stack.shared.mainContext
        return Account(cdObject: cdObject, context: moc)
    }

    /// Creates an MMO wrapping a given NSManagesObject.
    /// - Parameters:
    ///   - cdMessage: message to wrap
    ///   - context:    MOC suitable for the queue you want to use the returned Message on.
    ///                 Defaults the best suitable moc that can be found, which might lead to undefined behaviour.
    /// - Returns: MMO wrapping given NSManagedObject
    static func getFolder(fromCdObject cdObject: CdFolder,
                           context: NSManagedObjectContext? = nil) -> Folder {
        let moc: NSManagedObjectContext =
            context ?? cdObject.managedObjectContext ?? Stack.shared.mainContext
        return Folder(cdObject: cdObject, context: moc)
    }

    /// Creates an Identity wrapping a given CdIdentity.
    /// - Parameters:
    ///   - cdObject: object to wrap
    ///   - context:    MOC suitable for the queue you want to use the returned object on.
    ///                 Defaults the best suitable moc that can be found, which might lead to undefined behaviour.
    /// - Returns: Identity wrapping given CdIdentity
    static func getIdentity(fromCdIdentity cdObject: CdIdentity,
                              context: NSManagedObjectContext? = nil) -> Identity {
        let moc: NSManagedObjectContext =
            context ?? cdObject.managedObjectContext ??  Stack.shared.mainContext
        return Identity(cdObject: cdObject, context: moc)
    }

    /// Creates an ExtraKey wrapping a given CdExtraKey
    /// - Parameters:
    ///   - cdObject: object to wrap
    ///   - context:    MOC suitable for the queue you want to use the returned object on.
    ///                 Defaults the best suitable moc that can be found, which might lead to undefined behaviour.
    /// - Returns: MMO wrapping given CD-Object
    static func getExtraKey(fromCdExtraKey cdObject: CdExtraKey,
                            context: NSManagedObjectContext? = nil) -> ExtraKey {
        let moc: NSManagedObjectContext =
            context ?? cdObject.managedObjectContext ??  Stack.shared.mainContext
        return ExtraKey(cdObject: cdObject, context: moc)
    }

    /// Creates an ExtraKey wrapping a given CdClientCertificate
    /// - Parameters:
    ///   - cdObject: object to wrap
    ///   - context:    MOC suitable for the queue you want to use the returned object on.
    ///                 Defaults the best suitable moc that can be found, which might lead to undefined behaviour.
    /// - Returns: MMO wrapping given CD-Object
    static func getClientCertificate(fromCdClientCertificat cdObject: CdClientCertificate,
                            context: NSManagedObjectContext? = nil) -> ClientCertificate {
        let moc: NSManagedObjectContext =
            context ?? cdObject.managedObjectContext ??  Stack.shared.mainContext
        return ClientCertificate(cdObject: cdObject, context: moc)
    }
}
