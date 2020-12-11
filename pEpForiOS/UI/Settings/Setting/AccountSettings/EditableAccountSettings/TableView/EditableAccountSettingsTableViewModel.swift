////
////  EditableAccountSettingsTableViewModel.swift
////  pEp
////
////  Created by Alejandro Gelos on 08/10/2019.
////  Copyright © 2019 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//import MessageModel
//import pEpIOSToolbox
//
//protocol EditableAccountSettingsTableViewModelDelegate: class {
//    func reloadTable()
//}
//
//final class EditableAccountSettingsTableViewModel {
//    typealias TableInputs = (addrImap: String, portImap: String, transImap: String,
//        addrSmpt: String, portSmtp: String, transSmtp: String, accountName: String,
//        imapUsername: String, smtpUsername: String)
//
//    let securityViewModelvm = SecurityViewModel()
//
//    weak var delegate: EditableAccountSettingsTableViewModelDelegate?
//
//    /// If the credentials have either an IMAP or SMTP password,
//    /// it gets stored here.
//    var originalPassword: String?
//    var count: Int { return headers.count }
//    /// - Note: The email model is based on the assumption that imap.loginName == smtp.loginName
//    var password: String? {
//        didSet { passwordChanged = true }
//    }
//    var passwordChanged = false
//    var name: String?
//    var email: String
//    var imapUsername: String?
//    var smtpUsername: String?
//    var imapServer: EditableAccountSettingsViewModel.ServerViewModel?
//    var smtpServer: EditableAccountSettingsViewModel.ServerViewModel?
//    var headers: [String] = [NSLocalizedString("Account", comment: "Account settings"),
//                             NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"),
//                             NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")]
//
//    subscript(section: Int) -> String {
//        get {
//            assert(sectionIsValid(section: section), "Section out of range")
//            return headers[section]
//        }
//    }
//
//    init(account: Account, delegate: EditableAccountSettingsTableViewModelDelegate? = nil) {
//        // We are using a copy of the data here.
//        // The outside world must not know changed settings until they have been verified.
//        email = account.user.address
//        imapUsername = account.imapServer?.credentials.loginName
//        smtpUsername = account.smtpServer?.credentials.loginName
//        name = account.user.userName
//
//        if let server = account.imapServer {
//            originalPassword = server.credentials.password
//            imapServer = EditableAccountSettingsViewModel.ServerViewModel(address: server.address,
//                                                                          port: "\(server.port)",
//                transport: server.transport.asString())
//        } else {
//            imapServer = EditableAccountSettingsViewModel.ServerViewModel()
//        }
//
//        if let server = account.smtpServer {
//            originalPassword = originalPassword ?? server.credentials.password
//            smtpServer = EditableAccountSettingsViewModel.ServerViewModel(address: server.address,
//                                                                          port: "\(server.port)",
//                transport: server.transport.asString())
//        } else {
//            smtpServer = EditableAccountSettingsViewModel.ServerViewModel()
//        }
//        delegate?.reloadTable()
//    }
//
//    func validateInputs() throws -> TableInputs {
//        //IMAP
//        guard let addrImap = imapServer?.address, !addrImap.isEmpty else {
//            let msg = NSLocalizedString("IMAP server must not be empty.",
//                                        comment: "Empty IMAP server message")
//            throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
//        }
//
//        guard let portImap = imapServer?.port, !portImap.isEmpty else {
//            let msg = NSLocalizedString("IMAP Port must not be empty.",
//                                        comment: "Empty IMAP port server message")
//            throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
//        }
//
//        guard let transImap = imapServer?.transport, !transImap.isEmpty else {
//            let msg = NSLocalizedString("Choose IMAP transport security method.",
//                                        comment: "Empty IMAP transport security method")
//            throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
//        }
//
//        //SMTP
//        guard let addrSmpt = smtpServer?.address, !addrSmpt.isEmpty else {
//            let msg = NSLocalizedString("SMTP server must not be empty.",
//                                        comment: "Empty SMTP server message")
//            throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
//        }
//
//        guard let portSmtp = smtpServer?.port, !portSmtp.isEmpty else {
//            let msg = NSLocalizedString("SMTP Port must not be empty.",
//                                        comment: "Empty SMTP port server message")
//            throw AccountSettingsUserInputError.invalidInputPort(localizedMessage: msg)
//        }
//
//        guard let transSmtp = smtpServer?.transport, !transSmtp.isEmpty else {
//            let msg = NSLocalizedString("Choose SMTP transport security method.",
//                                        comment: "Empty SMTP transport security method")
//            throw AccountSettingsUserInputError.invalidInputTransport(localizedMessage: msg)
//        }
//
//        //other
//        guard let name = name, !name.isEmpty else {
//            let msg = NSLocalizedString("Account name must not be empty.",
//                                        comment: "Empty account name message")
//            throw AccountSettingsUserInputError.invalidInputAccountName(localizedMessage: msg)
//        }
//
//        guard let imapUsername = imapUsername, !imapUsername.isEmpty else {
//            let msg = NSLocalizedString("Imap username must not be empty.",
//                                        comment: "Empty username message")
//            throw AccountSettingsUserInputError.invalidInputUserName(localizedMessage: msg)
//        }
//
//        guard let smtpUsername = smtpUsername, !smtpUsername.isEmpty else {
//            let msg = NSLocalizedString("Smtp username must not be empty.",
//                                        comment: "Empty username message")
//            throw AccountSettingsUserInputError.invalidInputUserName(localizedMessage: msg)
//        }
//
//        return (addrImap: addrImap, portImap: portImap, transImap: transImap,
//                addrSmpt: addrSmpt, portSmtp: portSmtp, transSmtp: transSmtp, accountName: name,
//                imapUsername: imapUsername, smtpUsername: smtpUsername)
//    }
//}
//
//// MARK: - Private
//
//extension EditableAccountSettingsTableViewModel {
//
//    private func sectionIsValid(section: Int) -> Bool {
//        return section >= 0 && section < headers.count
//    }
//}
//
//// MARK: - HelpingStructures
//
//extension EditableAccountSettingsTableViewModel {
//    struct SecurityViewModel {
//        var options = Server.Transport.toArray()
//        var size : Int {
//            get {
//                return options.count
//            }
//        }
//
//        subscript(option: Int) -> String {
//            get {
//                return options[option].asString()
//            }
//        }
//    }
//}
