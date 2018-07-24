//
//  CdAccount+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdAccount {
    private func emailConnectInfos() -> [EmailConnectInfo] {
        return self.account().emailConnectInfos()
    }

    /**
     - Returns: The first found IMAP connect info. Used by some tests.
     */
    @available(*, deprecated, message: "use Account - imapConnectInfo() instead")
    var imapConnectInfo: EmailConnectInfo? {
        return emailConnectInfos().filter { return $0.emailProtocol == .imap }.first
    }

    /**
     - Returns: The first found SMTP connect info. Used by some tests.
     */
    @available(*, deprecated, message: "use Account - smtpConnectInfo() instead")
    var smtpConnectInfo: EmailConnectInfo? {
        return emailConnectInfos().filter { return $0.emailProtocol == .smtp }.first
    }

    @available(*, deprecated, message: "use Account - emailConnectInfos() instead")
    func emailConnectInfo(account: Account, server: Server,
                          credentials: ServerCredentials) -> EmailConnectInfo? {
        return Account.emailConnectInfo(account: account, server: server, credentials: credentials)
    }

    /**
     - Returns: A folder under this account with the given name.
     */
    open func folder(byName name: String) -> CdFolder? {
        return CdFolder.first(attributes: ["account": self, "name": name])
    }
}
