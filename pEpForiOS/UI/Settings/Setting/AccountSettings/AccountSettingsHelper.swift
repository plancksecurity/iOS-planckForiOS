//
//  AccountSettingsHelper.swift
//  pEp
//
//  Created by Martín Brude on 04/12/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import MessageModel

public struct AccountSettingsHelper {

    private var account: Account?

    init(account: Account) {
        self.account = account
    }

    public var hasClientCertificate: Bool {
        return account?.imapServer?.credentials.clientCertificate != .none
    }

    public var certificateDescription: String {
        guard let certificate = account?.imapServer?.credentials.clientCertificate else {
            Log.shared.errorAndCrash("Client Certificate not found")
            return ""
        }
        let name = certificate.label ?? "--"
        let date = certificate.date?.fullString() ?? ""
        let separator = NSLocalizedString("Exp. date:", comment: "separator string between name and date")
        return "\(name), \(separator) \(date)"
    }

    /// Provides the title of the row
    /// - Parameter type: The type of the row
    /// - Returns: the title of the row.
    func rowTitle(for type : AccountSettingsViewModel.RowType) -> String {
        switch type {
        case .name:
            return NSLocalizedString("Name", comment: "Name label in account settings")
        case .email:
            return NSLocalizedString("Email", comment: "Email label in account settings")
        case .password:
            return NSLocalizedString("Password", comment: "Password label in account settings")
        case .pepSync:
            return NSLocalizedString("p≡p Sync", comment: "pEp sync label in account settings")
        case .reset:
            return NSLocalizedString("Reset", comment: "Reset label in account settings")
        case .server:
            return NSLocalizedString("Server", comment: "Server label in account settings")
        case .port:
            return NSLocalizedString("Port", comment: "Port label in account settings")
        case .tranportSecurity:
            return NSLocalizedString("Transport Security",
                                     comment: "Transport security label in account settings")
        case .username:
            return NSLocalizedString("Username", comment: "User name label in account settings")
        case .oauth2Reauth:
            return NSLocalizedString("OAuth2 Reauthorization",
                                     comment: "OAuth2 Reauthorization label in account settings")
        case .includeInUnified:
            return NSLocalizedString("Include in Unified Folders",
                                     comment: "Include in Unified Folders label in account settings")
        case .signature:
            return NSLocalizedString("Signature", comment: "Signature label in account settings")
        case .certificate:
            return NSLocalizedString("Certificate", comment: "Certificate label in account settings")
        }
    }

    /// This method return the corresponding title for each section.
    /// - Parameter type: The section type to choose the proper title.
    /// - Returns: The title for the requested section.
    func sectionTitle(type: AccountSettingsViewModel.SectionType) -> String {
        switch type {
        case .account:
            return NSLocalizedString("Account", comment: "Tableview section  header: Account")
        case .imap:
            return NSLocalizedString("IMAP", comment: "Tableview section  header: IMAP")
        case .smtp:
            return NSLocalizedString("SMTP", comment: "Tableview section  header: IMAP")
        }
    }

    public struct CellsIdentifiers {
        static let oAuthCell = "oAuthTableViewCell"
        static let displayCell = "KeyValueTableViewCell"
        static let switchCell = "SwitchTableViewCell"
        static let dangerousCell = "DangerousTableViewCell"
        static let settingsCell = "settingsCell"
        static let settingsDisplayCell = "settingsDisplayCell"
    }
}
