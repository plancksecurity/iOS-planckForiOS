//
//  SecretUITestData.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

struct SecretUITestData: UITestDataProtocol {
    static let workingAccount1 = accountIosTest005
    static let workingAccount2 = accountIosTest006
    static let workingAccount3 = accountIosTest023

    static let accountIosTest005 = UIAccount(
        nameOfTheUser: "Rick Deckard",
        email: "iostest005@peptest.ch",
        imapServerName: "peptest.ch", smtpServerName: "peptest.ch",
        password: "pEpdichauf5MailPassword", imapPort: 993, smtpPort: 587,
        imapTransportSecurityString: "TLS", smtpTransportSecurityString: "StartTLS")

    static let accountIosTest006 = UIAccount(
        nameOfTheUser: "Bryant",
        email: "iostest006@peptest.ch",
        imapServerName: "peptest.ch", smtpServerName: "peptest.ch",
        password: "pEpdichauf5MailPassword", imapPort: 993, smtpPort: 587,
        imapTransportSecurityString: "TLS", smtpTransportSecurityString: "StartTLS")

    static let accountIosTest023 = UIAccount(
        nameOfTheUser: "Leon Kowalski",
        email: "test023@peptest.ch",
        imapServerName: "peptest.ch", smtpServerName: "peptest.ch",
        password: "pEpdichauf5MailPassword", imapPort: 993, smtpPort: 587,
        imapTransportSecurityString: "TLS", smtpTransportSecurityString: "StartTLS")

    static let workingYahooAccount = UIAccount(
        nameOfTheUser: "pep.test001@yahoo.com",
        email: "pep.test001@yahoo.com",
        imapServerName: "imap.mail.yahoo.com", smtpServerName: "smtp.mail.yahoo.com",
        password: "noDichAuf!", imapPort: 993, smtpPort: 587,
        imapTransportSecurityString: "TLS", smtpTransportSecurityString: "StartTLS")

    static let gmailOAuth2Account = UIAccount(
        nameOfTheUser: "abu peptest",
        email: "abu.peptest@gmail.com",
        imapServerName: "nomatter", smtpServerName: "nomatter",
        password: "hahanothinghaha", imapPort: 993, smtpPort: 587,
        imapTransportSecurityString: "TLS", smtpTransportSecurityString: "StartTLS")

    static let yahooOAuth2Account = UIAccount(
        nameOfTheUser: "peptest002@yahoo.com",
        email: "peptest002@yahoo.com",
        imapServerName: "sneakDichRein", smtpServerName: "nomatter",
        password: "nothing", imapPort: 993, smtpPort: 587,
        imapTransportSecurityString: "TLS", smtpTransportSecurityString: "StartTLS")

    static let manualAccount = UIAccount(
        nameOfTheUser: "Taffey Lewis",
        email: "doesNotExist@pep.digital",
        imapServerName: "peptest.ch", smtpServerName: "peptest.ch",
        password: "pEpdichauf5", imapPort: 993, smtpPort: 587,
        imapTransportSecurityString: "TLS", smtpTransportSecurityString: "StartTLS")

    static let manualAccountThatDoesNotWorkAutomatically = manualAccount
}

