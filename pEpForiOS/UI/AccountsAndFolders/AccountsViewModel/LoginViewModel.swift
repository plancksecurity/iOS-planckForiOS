//
//  LoginViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 26/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class LoginViewModel {   

    private var items: [LoginCellViewModel] = []
    var loginAccount : Account?
    var accountSettings: ASAccountSettings?
    var extendedLogin = false

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    public init () {
        items = [LoginCellViewModel]()
        generateBasicLogin()
    }

    func generateBasicLogin() {
        if !extendedLogin {
            // generamos el login de email pass login
        } else {
            generateExtendedLogin()
        }
    }

    func generateExtendedLogin() {
        if extendedLogin {

        }
    }

    func login(account: String, password: String, username: String? = nil,  callback: (NSError?) -> Void) {

        let user = ModelUserInfoTable()
        accountSettings = ASAccountSettings.init(accountName: account, provider: password,
                                                 flags: AS_FLAG_USE_ANY, credentials: nil)
        if accountSettings?.status == AS_OK, let acSettings = accountSettings {
            user.email = account
            user.password = password
            user.portIMAP = UInt16(acSettings.incoming.port)
            user.serverIMAP = acSettings.incoming.hostname
            user.portSMTP = UInt16(acSettings.outgoing.port)
            user.serverSMTP = acSettings.outgoing.hostname
            //fast fix remove me
            if username != nil {
                user.username = username
            } else {
                //FIXME
                if acSettings.incoming.username != "" {
                    user.username = acSettings.incoming.username
                } else {
                    user.username = account
                }
            }
            user.username = account
            if verifyAccount(model: user) {
                callback(nil)
            }
        } else {
            let err = NSError(domain: "Unable to find the server", code: 0, userInfo: nil)
            callback(err)
        }
    }

    func verifyAccount(model: ModelUserInfoTable) -> Bool {

        guard let addres = model.email, let email = model.email,
            let username = model.username, let serverIMAP = model.serverIMAP,
                let serverSMTP = model.serverSMTP else {
            return false
        }
        let identity = Identity.create(address: addres, userName: email)
        identity.isMySelf = true
        let imapServer = Server.create(serverType: .imap, port: model.portIMAP,
                                       address: serverIMAP,
                                       transport: model.transportIMAP.toServerTransport())
        imapServer.needsVerification = true
        let smtpServer = Server.create(serverType: .smtp, port: model.portSMTP,
                                       address: serverSMTP,
                                       transport: model.transportSMTP.toServerTransport())
        smtpServer.needsVerification = true
        let credentials = ServerCredentials.create(userName: username, password: model.password,
                                                   servers: [imapServer, smtpServer])
        credentials.needsVerification = true
        loginAccount = Account.create(identity: identity, credentials: [credentials])
        if let account = loginAccount {
            account.needsVerification = true
            account.save()
            return true
        }
        return false

    }

    subscript(index: Int) -> LoginCellViewModel {
        get {
            return self.items[index]
        }
    }

    var count: Int {
        return self.items.count
    }
}
