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

protocol NoActivatedAccountDelegate: AnyObject {
    /// Informs the VC that has to dismiss
    func dismissYourself()
    /// Show new account flow
    func showAccountSetupView()
}

/// Protocol that represents the basic data in a row.
protocol NoActivatedAccountRowProtocol {
    /// The type of the row
    var type : NoActivatedAccountViewModel.RowType { get }
    /// The title of the row.
    var title: String { get }
}

struct NoActivatedAccountViewModel {

    typealias ActionBlock = (() -> Void)
    typealias SwitchBlock = ((Bool) -> Void)

    /// Items to be displayed in a NoActivatedAccountViewController
    private (set) var items: [Section] = [Section]()

    public weak var delegate: NoActivatedAccountDelegate?

    /// Indicates if the view should be dismissed.
    public var shouldDismiss: Bool {
        return Account.countAll() > 0
    }

    init() {
        generateSections()
    }

    public func handleAddAccountButtonPressed() {
        delegate?.showAccountSetupView()
    }
}

//MARK: - enum & structs

extension NoActivatedAccountViewModel {

    public enum SectionType : String, CaseIterable {
        case accounts
    }

    /// Identifies semantically the type of row.
    public enum RowType : String, CaseIterable {
        case account
        case addNewAccount
    }

    /// Struct that represents a section in NoActivatedAccountViewController
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

    /// Struct that is used to perform an action. represents a ActionRow in NoActivatedAccountViewController
    public struct ActionRow: NoActivatedAccountRowProtocol {
        //The row type
        var type: NoActivatedAccountViewModel.RowType
        /// The title of the row.
        var title: String
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock?
    }

    /// Struct that is used to show and interact with a switch. represents a SwitchRow in settingsTableViewController
    public struct SwitchRow: NoActivatedAccountRowProtocol {
        //The row type
        var type: NoActivatedAccountViewModel.RowType
        //The title of the swith row
        var title: String
        /// action to be executed when switch toggle
        var action: SwitchBlock
    }
}

extension NoActivatedAccountViewModel {

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
            return NSLocalizedString("Accounts", comment: "Tableview section  header: Accounts").uppercased()
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
    /// - Returns: The rows. Every one must conform the NoActivatedAccountViewModelRowProtocol.
    private func generateRows(type: SectionType) -> [NoActivatedAccountRowProtocol] {
        var rows = [NoActivatedAccountRowProtocol]()
        switch type {
        case .accounts:
            Account.all(onlyActiveAccounts: false).forEach { (acc) in
                let accountRow = SwitchRow(type: .account,
                                           title: acc.user.address) { [weak self] in
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

    /// Handle the account activation
    ///
    /// - Parameter account: The account to activate
    private func handleAccountIsActivated(account: Account) {
        //Activate
        account.isActive = true
        account.session.commit()
        //Notify
        NotificationCenter.default.post(name: .pEpSettingsChanged,
                                        object: self,
                                        userInfo: nil)
        //Dismiss
        delegate?.dismissYourself()
    }
}
