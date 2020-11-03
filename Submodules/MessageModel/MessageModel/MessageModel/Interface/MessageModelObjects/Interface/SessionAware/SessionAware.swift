//
//  SessionAware.swift
//  MessageModel
//
//  Created by Andreas Buff on 28.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

public protocol SessionAware {
    associatedtype MMO: MessageModelObjectProtocol

    /// The session the MMO has been created- and is safe to use on.
    var session: Session { get }

    /// Creates a MessageModelObject that is save to use on the given session.
    ///
    /// - note: MUST be called on the queue the MMO has been created on!
    ///
    /// - Parameter session: session you want to use the MessageModelObject on
    /// - Returns: object you can savely use on the given session
    func safeForSession(_ session: Session) -> MMO

    /// Creates a MessageModelObject that is save to use on the given session.
    ///
    /// - note: MUST be called on the queue the MMO has been created on!
    ///
    /// - Parameters:
    ///   - object: object to garant save usage on given session for
    ///   - session: session the creted object should be save to be used on
    /// - Returns: object you can savely use on the given session
    static func makeSafe(_ object: MMO, forSession session: Session) -> MMO

    /// Creates a MessageModelObject that is save to use on the given session.
    ///
    /// - note: MUST be called on the queue the MMOs have been created on!
    ///
    /// - Parameters:
    ///   - objects: objects to garant save usage on given session for
    ///   - session: session the creted object should be save to be used on
    /// - Returns: objects you can savely use on the given session
    static func makeSafe(_ objects: [MMO], forSession session: Session) -> [MMO]

    /// Creates a new MessageModelObject on  a given session.
    ///
    /// Use if you need to create an MMO that must not be visible by any one outside the Session
    /// until you `commit()` the Session.
    ///
    /// - Parameter onSession: Session to create MMO on
    /// - Returns: MMO know by the given Session only
    static func newObject(onSession session: Session) -> MMO
}
