//
//  Server.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

public class Server: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol
    
    typealias T = CdServer
    let moc: NSManagedObjectContext
    let cdObject: T

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    // MARK: - Forwarded Getter & Setter
    
    public var serverType: ServerType {
        get {
            return cdObject.serverType
        }
        set {
            cdObject.serverType = newValue
        }
    }

    public var port: UInt16 {
        get {
            return UInt16(cdObject.port)
        }
        set {
            cdObject.port = Int16(newValue)
        }
    }

    public var address: String {
        get {
            return cdObject.address!
        }
        set {
            cdObject.address = newValue
        }
    }

    public var transport: Transport {
        get {
            return cdObject.transport
        }
        set {
            cdObject.transport = newValue
        }
    }

    public var authMethod: String? {
        get {
            return cdObject.authMethod
        }
        set {
            cdObject.authMethod = newValue
        }
    }

    public var automaticallyTrusted: Bool {
        get{
            // Only IMAP servers can be trusted.
            return cdObject.automaticallyTrusted
        }
        set{
            cdObject.automaticallyTrusted = newValue
        }
    }

    public var manuallyTrusted: Bool {
        get{
            // Only IMAP servers can be trusted.
            return cdObject.manuallyTrusted
        }
        set{
            cdObject.manuallyTrusted = newValue
        }
    }

    public  var credentials: ServerCredentials {
        get {
            return ServerCredentials(cdObject: cdObject.credentials!, context: moc)
        }
    }
    
    public var dateLastAuthenticationErrorShown: Date? {
        get {
            return cdObject.dateLastAuthenticationErrorShown    
        }
        
        set {
            cdObject.dateLastAuthenticationErrorShown = newValue
        }
    }

    //!!!: needs refactor. Topic: Verifyable account...
    // Used in test and in UI Account Setup

    /// Creates an Server instance with given data.
    ///
    /// - Parameters:
    ///   - serverType: type of sserver (IMAP, SMTP ...)
    ///   - port: server port
    ///   - address: server address
    ///   - transport: transport security
    ///   - authMethod: auth method
    ///   - trusted: whether or not pEp trusts the server
    /// - Returns: server instance with given data
    public static func create(serverType: ServerType, //!!!: used only by MM tests. Move to extension in MM test
                              port: UInt16,
                              address: String,
                            transport: Transport,
                            authMethod: String? = nil,
                            automaticallyTrusted: Bool = false,
                            manuallyTrusted: Bool = false,
                            credentials: ServerCredentials) -> Server {
        return create(serverType: serverType,
                      port: port,
                      address: address,
                      transport: transport,
                      authMethod: authMethod,
                      automaticallyTrusted: automaticallyTrusted,
                      manuallyTrusted: manuallyTrusted,
                      credentials: credentials,
                      toPersist: false)
    }

    private static func create(serverType: ServerType,  //!!!: used only by MM tests. Move to extension in MM test
                               port: UInt16,
                               address: String,
                               transport: Transport,
                               authMethod: String? = nil,
                               automaticallyTrusted: Bool = false,
                               manuallyTrusted: Bool = false,
                               credentials: ServerCredentials,
                               toPersist: Bool = true) -> Server {
        let server = Server(serverType: serverType,
                                 port: port,
                                 address: address,
                                 transport: transport,
                                 authMethod: authMethod,
                                 automaticallyTrusted: automaticallyTrusted,
                                 manuallyTrusted: manuallyTrusted,
                                 credentials: credentials)
        if toPersist {
            server.session.commit() //!!!: needs rethink. Topic: probaly Verifyable Account
        } else {
            // OAuth depends on having the accessToken saved in the Keychain.
            let key = credentials.cdObject.key ?? UUID().uuidString
            credentials.cdObject.key = key
            KeyChain.updateCreateOrDelete(password: credentials.password,
                                          forKey: key)
        }
        return server
    }

    private init(serverType: ServerType,
                 port: UInt16,
                 address: String,
                 transport: Transport,
                 authMethod: String? = nil,
                 automaticallyTrusted: Bool = false,
                 manuallyTrusted: Bool = false,
                 credentials: ServerCredentials,
                 session: Session = Session.main) {
        let moc = session.moc
        let createe = CdServer(context: moc)

        createe.serverType = serverType
        createe.port = Int16(port)
        createe.address = address
        createe.transport = transport
        createe.authMethod = authMethod
        createe.credentials = credentials.cdObject
        createe.automaticallyTrusted = automaticallyTrusted
        createe.manuallyTrusted = manuallyTrusted

        self.cdObject = createe
        self.moc = moc
    }

    public convenience init(withDataFrom server: Server) {
        //!!!: create CdServer.clone() and use it
        self.init(serverType: server.serverType,
                  port: server.port,
                  address: server.address,
                  transport: server.transport,
                  authMethod: server.authMethod,
                  automaticallyTrusted: server.automaticallyTrusted,
                  manuallyTrusted: server.manuallyTrusted,
                  credentials: ServerCredentials(withDataFrom: server.credentials))
    }
    
    public static func by(account: Account, serverType: ServerType) -> Server? {
        let cdAccount = account.cdObject
        guard let cdServer = cdAccount.server(type: serverType) else {
            Log.shared.errorAndCrash("Server not found")
            return nil
        }
        return MessageModelObjectUtils.getServer(fromCdObject: cdServer)
    }
}
