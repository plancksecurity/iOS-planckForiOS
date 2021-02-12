//
//  Identity.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class Identity: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol
    
    typealias T = CdIdentity
    let moc: NSManagedObjectContext
    let cdObject: T

    // MARK: - Life Cycle
    
    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    /// Updates or creates Identity with the given data.
    ///
    /// - Parameters:
    ///   - address: email address, also used as key for identifying existing Identity(s)
    ///   - userID: user ID
    ///   - addressBookID: Apple Contacts ID
    ///   - userName: display name
    ///   - session: session to work on. Defaults to main.
    //!!!: the UI should not see user_id. Maybe more, plus probaly most visible fields shoud be read only.
    public init(address: String,
                userID: String? = nil,
                addressBookID: String? = nil,
                userName: String? = nil,
                session: Session? = Session.main) {
        let moc = session?.moc ?? Session.main.moc
        let createe = CdIdentity.updateOrCreate(withAddress: address,
                                                userID: userID,
                                                addressBookID: addressBookID,
                                                userName: userName,
                                                context: moc)
        self.cdObject = createe
        self.moc = moc
    }

    //!!!: impl CdIdentity.clone() and use it.
    convenience public init(identity: Identity) {
        self.init(address: identity.address,
                  userID: identity.userID,
                  addressBookID: identity.addressBookID,
                  userName: identity.userName)
    }

    // MARK: - Async pEp session support

    func fingerprint(completion: @escaping (String?) -> ()) {
        cdObject.fingerprint(completion: completion)
    }

    // MARK: - Forwarded Getter & Setter

    public var address: String {
        get {
            return cdObject.address!
        }
        set {
            cdObject.address = newValue
        }
    }

    //!!!: should not be visible for clients. Internal Model info.
    public var userID: String {
        return cdObject.userID!
    }

    public private(set) var addressBookID: String? {
        get {
            return cdObject.addressBookID
        }
        set {
            cdObject.addressBookID = newValue
        }
    }

    public var userName: String? {
        return cdObject.userName
    }

    public var isMySelf: Bool {
        return cdObject.isMySelf
    }

    public var language: String? {
        return cdObject.language
    }

    public var displayString: String {
        if let uname = userName {
            return "\(uname) <\(address)>"
        }
        return address
    }

    public var userNameOrAddress: String {
        return userName ?? address
    }
}

// MARK: - Static

//!!!: move to fetch extension. See Account.Fetch
extension Identity {

    public static func all(in session: Session? = Session.main) -> [Identity] {
        let moc = session?.moc ?? Session.main.moc
        guard let cdIdentities = CdIdentity.all(in: moc) as? [CdIdentity] else {
            return []
        }
        return cdIdentities.map { MessageModelObjectUtils.getIdentity(fromCdIdentity: $0) }
    }

    // Finds an Identity by address
    ///
    /// - note: The client (YOU) are responsible for usage on correct session.
    ///
    /// - Parameters:
    ///   - address: address to search Identity for
    ///   - session: session to work on. Defaults to .main
    /// - Returns: Found Identity if any, nil otherwize
    public static func by(address: String, session: Session? = Session.main) -> Identity? {
        let moc = session?.moc ?? Session.main.moc
        guard let id = CdIdentity.search(address: address, context: moc) else {
            // We found nothing.
            return nil
        }
        return MessageModelObjectUtils.getIdentity(fromCdIdentity: id)
    }
}

extension Identity: Equatable {
    public static func ==(lhs: Identity, rhs: Identity) -> Bool {
        return lhs.address == rhs.address
    }
}

extension Identity: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address.hashValue)
    }
}

// MARK: - Custom{Debug}StringConvertible

extension Identity: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<Identity \(displayString) userID: \(String(describing: userID)) mySelf: \(isMySelf)>"
    }
}

extension Identity: CustomStringConvertible {
    public var description: String {
        return debugDescription
    }
}
