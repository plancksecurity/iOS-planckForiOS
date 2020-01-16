//
//  SettingsViewModelV2.swift
//  pEp
//
//  Created by Xavier Algarra on 15/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

/// Protocol that represents the basic data in a row.
protocol SettingsRowProtocol {
    /// Title of the row.
    var title: String { get set }
    /// boolean that indicates if the row action is dangerous.
    var isDangerous: Bool { get set }
}

/// View Model for SettingsTableViewController
final class SettingsViewModelV2 {

    /// Struct that represents a section in settingsTableViewController
    struct Section {
        /// Title of the section
        var title: String
        /// footer of the section
        var footer: String?
        /// list of rows in the section
        var rows: [SettingsRowProtocol]?
    }

    /// Struct that is used to perform an action. represents a ActionRow in settingsTableViewController
    struct ActionRow: SettingsRowProtocol {
        var title: String
        var isDangerous: Bool = false
        /// Block that will be executed when action cell is pressed
        var action: (() -> Void)
    }

    /// Struct that is used to perform a show detail action. represents a NavicationRow in SettingsTableViewController
    struct NavigationRow: SettingsRowProtocol {
        var title: String
        /// subtitle for a navigation row
        var subtitle: String?
        var isDangerous: Bool = false
    }

    /// Struct that is used to show and interact with a switch. represents a SwitchRow in settingsTableViewController
    struct SwitchRow: SettingsRowProtocol {
        var title: String
        var isDangerous: Bool
        /// Value of the switch
        var isOn: Bool
        /// action to be executed when switch toggle
        var action: ((Bool) -> Void)
    }

    /// Items to be displayed in a SettingsTableViewController
    private (set) var items: [Section] = [Section]()

    /// Number of elements in items
    var count: Int {
        get {
            return items.count
        }
    }

    ///Access method to get the sections
    subscript (index: Int) -> Section {
        return items[index]
    }

    /// Constructor for SettingsViewModel
    init() {
        setup()
    }

    // MARK: - Private

    private enum SectionType {
        case accounts
        case globalSettings
        case keySync
        case contacts
        case companyFeatures
    }

    private func setup() {
        generateSections()
    }

    private func generateSections() {
        items.append(Section(title: sectionTitles(type: .accounts),
        footer: sectionFooter(type: .accounts),
        rows: generateRows(type: .accounts)))

        items.append(Section(title: sectionTitles(type: .globalSettings),
        footer: sectionFooter(type: .globalSettings),
        rows: generateRows(type: .globalSettings)))

        items.append(Section(title: sectionTitles(type: .keySync),
        footer: sectionFooter(type: .keySync),
        rows: generateRows(type: .keySync)))

        items.append(Section(title: sectionTitles(type: .contacts),
        footer: sectionFooter(type: .contacts),
        rows: generateRows(type: .contacts)))

        items.append(Section(title: sectionTitles(type: .companyFeatures),
        footer: sectionFooter(type: .companyFeatures),
        rows: generateRows(type: .companyFeatures)))
    }

    private func generateRows(type: SectionType) -> [SettingsRowProtocol] {
        var rows = [SettingsRowProtocol]()
        switch type {
        case .accounts:
            Account.all().forEach { (acc) in
                let accountRow = ActionRow(title: acc.user.address,
                                           isDangerous: false, action: { [weak self] in
                    guard let me = self else {
                        Log.shared.errorAndCrash(message: "Lost myself")
                        return
                    }
                    me.delete(account: acc)
                })
                rows.append(accountRow)
            }
            return rows
        default:
            return rows
        }

    }

    private func sectionTitles(type: SectionType) -> String {
        switch type {
        case .accounts:
            return NSLocalizedString("Accounts", comment: "Tableview section  header")
        case .globalSettings:
            return NSLocalizedString("Global Settings", comment: "Tableview section header")
        case .keySync:
            return NSLocalizedString("p≡p sync", comment: "Tableview section header")
        case .contacts:
            return NSLocalizedString("Contacts", comment: "TableView section header")
        case .companyFeatures:
            return NSLocalizedString("Enterprise Features", comment: "Tableview section header")
        }
    }

    private func sectionFooter(type: SectionType) -> String? {
        switch type {
        case .accounts, .keySync, .companyFeatures:
            return nil
        case .globalSettings:
            return NSLocalizedString("Public key material will only be attached to a message if p≡p detects that the recipient is also using p≡p.",
                                     comment: "passive mode description")
        case .contacts:
            return NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.",
                                       comment: "TableView Contacts section footer")
        }
    }

    func delete(account: Account) {

        let oldAddress = account.user.address
        account.delete()
        Session.main.commit()

        if Account.all().count == 1,
            let account = Account.all().first {
            do {
                if try !account.isKeySyncEnabled() {
                    AppSettings.shared.keySyncEnabled = false
                }
            } catch {
                Log.shared.errorAndCrash("Fail to get account pEpSync state")
            }
        }

        if AppSettings.shared.defaultAccount == oldAddress {
            let newDefaultAccount = Account.all().first
            guard let newDefaultAddress = newDefaultAccount?.user.address else {
                return
                //no more accounts, no default account
            }
            AppSettings.shared.defaultAccount = newDefaultAddress
        }
    }
}


        //items.append(Section(type: .accounts))

//
//        items.append(Section(title: sectionTitles(type: .accounts),
//                             footer: sectionFooter(type: .accounts),
//                             rows: generateRows(type: .accounts)))


        //Section(title: T##String, footer: T##String, rows: T##[SettingsRowProtocol])
//        items.append(Section())//(SettingsSectionViewModel(type: .accounts))
//        items.append(SettingsSectionViewModel(type: .globalSettings))
//        items.append(SettingsSectionViewModel(type: .keySync))
//        items.append(SettingsSectionViewModel(type: .contacts))
//        items.append(SettingsSectionViewModel(type: .companyFeatures))
