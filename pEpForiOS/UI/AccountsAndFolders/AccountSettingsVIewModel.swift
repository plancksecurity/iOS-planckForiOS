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

    private var account: Account?
    private var headers: [String]

    public init(account: Account) {
        headers = [String]()
        headers.append(NSLocalizedString("Account", comment: "Account settings"))
        headers.append(NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"))
        headers.append(NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP"))
        self.account = account
    }

    var email: String {
        get {
            if let acc = account {
                return acc.user.address
            }
            return ""
        }
    }

    var loginName: String {
        get {
            if let loginName = account?.serverCredentials.array.first?.userName {
                return loginName
            }
            return ""
        }
    }

    var name: String {
        get {
            if let name = account?.user.userName {
                return name
            }
            return ""
        }
    }

    var smtpServer: (address: String?, port: String?, transport: String?) {
        //fixme only support one server
        get {
            if let server = account?.smtpServers.first {
                return (server.address, "\(server.port)", server.transport?.asString())
            }
            return (nil,nil,nil)
        }
    }

    var imapServer: (address: String?, port: String?, transport: String?) {
        //fixme only support one servers
        get {
            if let server = account?.imapServers.first {
                return (server.address, "\(server.port)", server.transport?.asString())
            }
            return (nil,nil,nil)
        }
    }

    //fixme need to rethought the server update things
    func update(loginName: String, name: String, password: String? = nil,
                imap: (address: String?, port: String?, transport: String?),
                smtp: (address: String?, port: String?, transport: String?)) {
        //lala
    }

    //fixme temporal function without server
    func update(loginName: String, name: String, password: String? = nil) {
        self.account?.user.userName = name
        self.account?.serverCredentials.forEach({ (servercredentials) in
            servercredentials.userName = loginName
            servercredentials.password = password
            servercredentials.save()
        })
        self.account?.user.save()
        self.account?.save()
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
