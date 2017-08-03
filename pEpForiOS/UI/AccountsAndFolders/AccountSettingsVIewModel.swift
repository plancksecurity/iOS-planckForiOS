//
//  AccountSettingsVIewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class AccountSettingsViewModel {

    public struct ServerViewModel {
        let address: String?
        let port: String?
        let transport: String?

        static func emptyViewModel() -> ServerViewModel {
            return ServerViewModel(address: nil, port: nil, transport: nil)
        }
    }

    public struct SecurityViewModel {

        var options = Server.Transport.toArray()
        var size : Int {
            get {
                return options.count
            }
        }

        subscript(option: Int) -> String {
            get {
                return options[option].asString()
            }
        }
    }

    private var account: Account
    private var headers: [String]

    public let svm = SecurityViewModel()

    public init(account: Account) {
        headers = [String]()
        headers.append(NSLocalizedString("Account", comment: "Account settings"))
        headers.append(NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"))
        headers.append(NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP"))
        self.account = account
    }

    var email: String {
        get {
            return account.user.address
        }
    }

    var loginName: String {
        get {
            return account.serverCredentials.array.first?.userName ?? ""
        }
    }

    var name: String {
        get {
            return account.user.userName ?? ""
        }
    }

    var smtpServer: ServerViewModel {
        get {
            if let server = account.smtpServer {
                return ServerViewModel(address: server.address, port: "\(server.port)", transport: server.transport?.asString())
            }
            return ServerViewModel.emptyViewModel()
        }
    }

    var imapServer: ServerViewModel {
        get {
            if let server = account.imapServer {
                return ServerViewModel(address: server.address, port: "\(server.port)", transport: server.transport?.asString())
            }
            return ServerViewModel.emptyViewModel()
        }
    }

    //fixme need to rethought the server update things
    func update(loginName: String, name: String, password: String? = nil,
                imap: (address: String, port: String, transport: String),
                smtp: (address: String, port: String, transport: String)) {
//        let imapServer = account?.imapServer

        //HERE:
        self.account.user.userName = name
        self.account.serverCredentials.forEach({ (sc) in
            sc.userName = loginName
            if password != nil && password != "" {
                sc.password = password
            }
            var servers = [Server]()
            //fixme remove the !
            //BUFF: creates duplicate server not assigned to account
            servers.append(
                Server.create(serverType: Server.ServerType.imap,
                              port: UInt16(imap.port)!,
                              address: imap.address,
                              transport: Server.Transport(fromString: imap.transport)))

            servers.append(
                Server.create(serverType: Server.ServerType.smtp,
                              port: UInt16(smtp.port)!,
                              address: smtp.address,
                              transport: Server.Transport(fromString: smtp.transport)))

            sc.servers = MutableOrderedSet(array: servers)
            sc.save()
        })
        self.account.save()
    }

    func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section <= headers.count
    }

    var count: Int {
        get {
            return headers.count
        }
    }

    subscript(section: Int) -> String {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return headers[section]
        }
    }
}
