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

    var loginAccount : Account?
    var accountSettings: ASAccountSettings?

    func handleFirstLogin() -> Bool {
        return Account.all().isEmpty
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
            /*if username != nil {
                user.username = username
            } else {
                user.username = acSettings.incoming.username
            }*/
            //fast fix remove me
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
}
