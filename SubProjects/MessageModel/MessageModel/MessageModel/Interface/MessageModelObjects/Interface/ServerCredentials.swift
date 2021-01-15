//
//  ServerCredentials.swift
//  MessageModel
//
//  Created by Igor Vojinovic on 10/21/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class ServerCredentials: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdServerCredentials
    let moc: NSManagedObjectContext
    let cdObject: T

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    // MARK: - Life Cycle

    /// - Parameters:
    ///   - loginName: user name to use in username&password authentication
    ///   - key: UUID used as KecVAlue key to retreive the password from the Key Chain
    ///   - clientCertificate:  client certificate to connect to server with. Set to `nil` if the
    ///                         server does not require a client certificate.
    ///   - session: session to create the ServerCredentials on
    public init(loginName: String,
                key: String? = nil,
                clientCertificate: ClientCertificate?,
                session: Session = Session.main) {
        let moc = session.moc
        let createe = CdServerCredentials(context: moc)

        createe.loginName = loginName
        createe.key = key
        createe.clientCertificate = clientCertificate?.cdObject

        self.cdObject = createe
        self.moc = moc
    }

    // MARK: - Forwarded Getters & Setters

    public var password: String? {
        get {
            return cdObject.password
        }
        set {
            cdObject.password = newValue
        }
    }

    public var key: String? { //???: *double check/ re-think, maybe move key logic. 
        get {
            return cdObject.key
        }
    }

    public var loginName: String {
        get {
            return cdObject.loginName!
        }
        set {
            cdObject.loginName = newValue
        }
    }

    public var clientCertificate: ClientCertificate? {
        get {
            guard let cdClientCertificate = cdObject.clientCertificate else {
                // This is a valid case. Client certs are optional. The server using us does not
                // require a client cert.
                return nil
            }
            return MessageModelObjectUtils.getClientCertificate(fromCdClientCertificat: cdClientCertificate,
                                                                context: moc)
        }
        set {
            cdObject.clientCertificate = newValue?.cdObject
        }
    }

    public convenience init(withDataFrom orig: ServerCredentials) {
        self.init(loginName: orig.loginName, key: orig.key, clientCertificate: orig.clientCertificate)
    }
}
