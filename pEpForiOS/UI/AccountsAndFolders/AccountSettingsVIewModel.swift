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

    public init(account: Account) {
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
            if let loginName = account?.user.userName {
                return loginName
            }
            return ""
        }
    }

    var name: String {
        get {
            if let name = account?.user.displayString {
                return name
            }
            return ""
        }
    }

    var smtpServer: (address: String?, port: String?) {
        get {
            if let server = account?.smtpServers.first {
                return (server.address, "\(server.port)")
            }
            return (nil,nil)
        }
    }

    var imapServer: (address: String?, port: String?) {
        get {
            if let server = account?.imapServers.first {
                return (server.address, "\(server.port)")
            }
            return (nil,nil)
        }
    }

}
