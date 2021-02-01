//
//  CdAccount+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox
import PantomimeFramework

extension CdAccount {
    private func connectInfos() -> [EmailConnectInfo] {
        var result = [EmailConnectInfo]()
        guard let servers = servers?.allObjects as? [CdServer] else {
            return result
        }

        for server in servers {
            guard
                server.serverType == Server.ServerType.imap ||
                    server.serverType == Server.ServerType.smtp
                else {
                    Log.shared.errorAndCrash("Unsupported server type")
                    continue
            }

            let credentials = server.credentialsOrCrash

            if let connectInfo = connectInfo(server: server,
                                                       credentials: credentials) {
                result.append(connectInfo)
            }
        }

        return result
    }

    func connectInfo(server: CdServer,
                          credentials: CdServerCredentials) -> EmailConnectInfo? {
        let connectionTransport = server.transport

        guard
            let emailProtocol = EmailProtocol(serverType: server.serverType)
            else {
                Log.shared.errorAndCrash("Missing emailProtocol")
                return nil
        }

        guard let transport = ConnectionTransport(fromInt: Int(connectionTransport.rawValue)) else {
            return nil
        }

        return EmailConnectInfo(account: self,
                                server: server,
                                credentials: credentials,
                                loginName: credentials.loginNameOrCrash,
                                networkAddress: server.addressOrCrash,
                                networkPort: UInt16(server.port),
                                emailProtocol: emailProtocol,
                                connectionTransport: transport,
                                authMethod: AuthMethod(string: server.authMethod))
    }

    /**
     - Returns: The first found IMAP connect info.
     */
    var imapConnectInfo: EmailConnectInfo? {
        return connectInfos().filter { return $0.emailProtocol == .imap }.first
    }

    /**
     - Returns: The first found SMTP connect info.
     */
    var smtpConnectInfo: EmailConnectInfo? {
        return connectInfos().filter { return $0.emailProtocol == .smtp }.first
    }

    /**
     - Returns: A folder under this account with the given name.
     */
    func folder(byName name: String, context: NSManagedObjectContext) -> CdFolder? {
        return CdFolder.first(attributes: ["account": self, "name": name], in: context)
    }
}

extension CdAccount {

    /// Inform MessageQueryResult about a change in Unified Folders status.
    /// This method does NOT save the context. 
    public func setIsUnifiedTriggeringQueryResultsChange() {
        let predicate = NSPredicate(format: "parent.%@ = %@", CdFolder.RelationshipName.account, self)
        let moc = Session.main.moc
        let messages: [CdMessage] = CdMessage.all(predicate: predicate, in: moc) ?? []
        messages.forEach { (message) in
            let tmpParent = message.parent
            message.parent = tmpParent
        }
    }
}
