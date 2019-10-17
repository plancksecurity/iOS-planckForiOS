//
//  EditableAccountSettingsTableViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

final class EditableAccountSettingsTableViewModel {
    let securityViewModelvm = SecurityViewModel()

    var count: Int { return headers.count }
    /// - Note: The email model is based on the assumption that imap.loginName == smtp.loginName
    var email: String
    var name: String
    var password: String
    var imapPort: String
    var smtpPort: String
    var username: String
    var imapServer: String
    var smtpServer: String
    var imapSecurity: String
    var smtpSecurity: String
    var headers: [String] = [NSLocalizedString("Account", comment: "Account settings"),
                               NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"),
                               NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")]

    subscript(section: Int) -> String {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return headers[section]
        }
    }

    func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < headers.count
    }

    func footerFor(section: Int) -> String {
        if section < footers.count {
            return footers[section]
        }
        return ""
    }

    func validateInputs() throws -> (addrImap: String, portImap: String, transImap: String,
        addrSmpt: String, portSmtp: String, transSmtp: String, accountName: String,
        loginName: String) {
            //IMAP
            guard let addrImap = imapServerTextfieldText, !addrImap.isEmpty else {
                let msg = NSLocalizedString("IMAP server must not be empty.",
                                            comment: "Empty IMAP server message")
                throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
            }

            guard let portImap = imapPortTextfieldText, !portImap.isEmpty else {
                let msg = NSLocalizedString("IMAP Port must not be empty.",
                                            comment: "Empty IMAP port server message")
                throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
            }

            guard let transImap = imapSecurityTextfieldText, !transImap.isEmpty else {
                let msg = NSLocalizedString("Choose IMAP transport security method.",
                                            comment: "Empty IMAP transport security method")
                throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
            }

            //SMTP
            guard let addrSmpt = smtpServerTextfieldText, !addrSmpt.isEmpty else {
                let msg = NSLocalizedString("SMTP server must not be empty.",
                                            comment: "Empty SMTP server message")
                throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
            }

            guard let portSmtp = smtpPortTextfieldText, !portSmtp.isEmpty else {
                let msg = NSLocalizedString("SMTP Port must not be empty.",
                                            comment: "Empty SMTP port server message")
                throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
            }

            guard let transSmtp = smtpSecurityTextfieldText, !transSmtp.isEmpty else {
                let msg = NSLocalizedString("Choose SMTP transport security method.",
                                            comment: "Empty SMTP transport security method")
                throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
            }

            //other
            guard let name = nameTextfieldText, !name.isEmpty else {
                let msg = NSLocalizedString("Account name must not be empty.",
                                            comment: "Empty account name message")
                throw AccountSettingsUserInputError.invalidInputAccountName(localizedMessage: msg)
            }

            guard let loginName = usernameTextfieldText, !loginName.isEmpty else {
                let msg = NSLocalizedString("Username must not be empty.",
                                            comment: "Empty username message")
                throw AccountSettingsUserInputError.invalidInputUserName(localizedMessage: msg)
            }

            return (addrImap: addrImap, portImap: portImap, transImap: transImap,
                    addrSmpt: addrSmpt, portSmtp: portSmtp, transSmtp: transSmtp, accountName: name,
                    loginName: loginName)
    }
}


// MARK: - Private

extension EditableAccountSettingsTableViewModel {
    private var footers: [String] {
        return [NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.", comment: "Footer for Account settings section 1")]
    }
}


// MARK: - HelpingStructures

extension EditableAccountSettingsTableViewModel {
    struct SecurityViewModel {
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
}
