import MessageModel

class SecretTestData: TestDataBase {
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

            password: "pwd"))
        /*
         //#########
         //# 005 #
         append(accountSettings: AccountSettings(
         accountName: "iostest005",
         idAddress: "iostest005@peptest.ch",
         idUserName: "iostest005@peptest.ch",

         imapServerAddress: "peptest.ch",
         imapServerType: Server.ServerType.imap,
         imapServerTransport: Server.Transport.tls,
         imapServerPort: 993,

         smtpServerAddress: "peptest.ch",
         smtpServerType: Server.ServerType.smtp,
         smtpServerTransport: Server.Transport.startTls,
         smtpServerPort: 587,

         password: "pEpdichauf5MailPassword"))

         //#########
         //# 004 #
         append(accountSettings: AccountSettings(
         accountName: "iostest004",
         idAddress: "iostest004@peptest.ch",
         idUserName: "iostest004@peptest.ch",

         imapServerAddress: "peptest.ch",
         imapServerType: Server.ServerType.imap,
         imapServerTransport: Server.Transport.tls,
         imapServerPort: 993,

         smtpServerAddress: "peptest.ch",
         smtpServerType: Server.ServerType.smtp,
         smtpServerTransport: Server.Transport.startTls,
         smtpServerPort: 587,

         password: "pEpdichauf5MailPassword"))
         // etc.
         */
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

            password: "pEpdichauf5MailPassword"))
    }
}


