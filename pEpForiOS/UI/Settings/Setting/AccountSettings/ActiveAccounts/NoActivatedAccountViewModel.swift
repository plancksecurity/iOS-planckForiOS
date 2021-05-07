//
//  NoActivatedAccountViewModel.swift
//  pEp
//
//  Created by Martín Brude on 7/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox


protocol NoActivatedAccountDelegate: class {
    /// Informs the VC that has to dismiss
    func dismissYourself()
}

/// Protocol that represents the basic data in a row.
protocol NoActivatedAccountRowProtocol {
    /// The type of the row
    var type : NoActivatedAccountViewModel.RowType { get }
    /// The title of the row.
    var title: String { get }
    /// Returns the cell identifier based on the index path.
    var cellIdentifier: String { get }
}

struct NoActivatedAccountViewModel {

    /// Items to be displayed in a SettingsTableViewController
    private (set) var items: [Section] = [Section]()

    public enum SectionType : String, CaseIterable {
        case accounts
    }

    /// Identifies semantically the type of row.
    public enum RowType : String, CaseIterable {
        case account
        case addNew
    }

    /// Struct that represents a section in SettingsTableViewController
    public struct Section: Equatable {
        /// Title of the section
        var title: String
        /// footer of the section
        var footer: String?
        /// list of rows in the section
        var rows: [NoActivatedAccountRowProtocol]
        /// type of the section
        var type: SectionType

        static func == (lhs: NoActivatedAccountViewModel.Section, rhs: NoActivatedAccountViewModel.Section) -> Bool {
            return (lhs.title == rhs.title && lhs.footer == rhs.footer)
        }
    }

    /// Indicates if the view should be dismissed.
    public var shouldDismiss: Bool {
        return Account.countAll() > 0
    }

    init() {
        self.generateSections()
    }

    private mutating func generateSections() {
        NoActivatedAccountViewModel.SectionType.allCases.forEach { (type) in
            items.append(sectionForType(sectionType: type))
        }
    }

    private func sectionForType(sectionType: SectionType) -> Section {
        return Section(title: sectionTitle(type: sectionType),
                       footer: sectionFooter(type: sectionType),
                       rows: generateRows(type: sectionType),
                       type: sectionType)
    }

    /// This method return the corresponding title for each section.
    /// - Parameter type: The section type to choose the proper title.
    /// - Returns: The title for the requested section.
    private func sectionTitle(type: SectionType) -> String {
        switch type {
        case .accounts:
            return NSLocalizedString("Accounts", comment: "Tableview section  header: Accounts")
        }
    }

    /// Thie method provides the title for the footer of each section.
    /// - Parameter type: The section type to get the proper title
    /// - Returns: The title of the footer.
    private func sectionFooter(type: SectionType) -> String? {
        switch type {
        case .accounts:
            return NSLocalizedString("You have disabled all your accounts. You could either enable existing accounts or add a new account", comment: "Accounts section, footer")
        }
    }

    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: An array with the settings rows. Every setting row must conform the NoActivatedAccountViewModelRowProtocol.
    private func generateRows(type: SectionType) -> [NoActivatedAccountRowProtocol] {
        var rows = [NoActivatedAccountRowProtocol]()
        switch type {
        case .accounts:
            Account.all(onlyActiveAccounts: false).forEach { (acc) in
                let accountRow = ActionRow(type: .account, cellIdentifier: "", title: acc.user.address) {
                    guard let me = self else {
                        Log.shared.errorAndCrash("Lost myself")
                        return
                    }
                    handleAccountIsActivated(account: account)
                }
                rows.append(accountRow)
            }
            return rows
        }
    }
    private func handleAccountIsActivated(account: Account) {
        account.isActive = true
        account.session.commit()
        NotificationCenter.default.post(name: .pEpSettingsChanged,
                                        object: self,
                                        userInfo: nil)
        delegate?.dismiss()

    }
}

extension NoActivatedAccountViewModel {

    typealias ActionBlock = (() -> Void)

    /// Identifies semantically the type of row.
    public enum RowIdentifier: String {
        case account
        case addAccount
    }

    /// Struct that is used to perform an action. represents a ActionRow in NoActivatedAccountViewController
    public struct ActionRow: NoActivatedAccountRowProtocol {
        var type: NoActivatedAccountViewModel.RowType
        /// Cell identifier
        var cellIdentifier: String
        /// The type of the row.
        var title: String
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock?
    }
}
