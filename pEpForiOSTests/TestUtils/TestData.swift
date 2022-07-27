import MessageModel

class TestData: TestDataBase {
    override func populateAccounts() {
        addLocalTestAccount(userName: "test001")
        addLocalTestAccount(userName: "test002")
        addLocalTestAccount(userName: "test003")
    }

    override func populateVerifiableAccounts() {
        addVerifiablePepTestAccount(address: "unittest.ios.1@peptest.ch")
        addVerifiablePepTestAccount(address: "unittest.ios.2@peptest.ch")
    }

    func addLocalTestAccount(userName: String) {
        let address = "\(userName)@localhost"
        append(accountSettings: AccountSettings(
            accountName: "Unit Test \(address)",
            idAddress: address,
            idUserName: "User \(address)",

            imapLoginName: userName,
            imapServerAddress: "localhost",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.plain,
            imapServerPort: 3143,

            smtpLoginName: userName,
            smtpServerAddress: "localhost",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.plain,
            smtpServerPort: 3025,

            imapPassword: "pwd",
            smtpPassword: "pwd"))
    }

    func addVerifiablePepTestAccount(address: String) {
        append(verifiableAccountSettings: AccountSettings(
                accountName: "Unit Test \(address)",
                idAddress: address,
                idUserName: "User \(address)",
                
                imapServerAddress: "peptest.ch",
                imapServerType: Server.ServerType.imap,
                imapServerTransport: Server.Transport.tls,
                imapServerPort: 993,
                
                smtpServerAddress: "peptest.ch",
                smtpServerType: Server.ServerType.smtp,
                smtpServerTransport: Server.Transport.startTls,
                smtpServerPort: 587,
                
                imapPassword: "pEpdichauf5MailPassword",
                smtpPassword: "pEpdichauf5MailPassword"))
    }
}


