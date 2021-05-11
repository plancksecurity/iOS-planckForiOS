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

class NoActivatedAccountViewModel {

    typealias ActionBlock = (() -> Void)
    typealias SwitchBlock = ((Bool) -> Void)

    /// Items to be displayed in a NoActivatedAccountViewController
    public private(set) var sections: [Section] = [Section]()

    /// Delegate to communicate with NoActivatedAccountViewController
    public weak var delegate: NoActivatedAccountDelegate?

    /// Constructor
    /// 
    /// - Parameter delegate: The delegate to communicate to VC.
    init(delegate: NoActivatedAccountDelegate) {
        generateSections()
        self.delegate = delegate
    }
}

//MARK: - enum & structs

extension NoActivatedAccountViewModel {

    /// Identifies the sections
    public enum SectionType : String, CaseIterable {
        case accounts
    }

    /// Identifies semantically the type of row.
    public enum RowType : String, CaseIterable {
        case account
        case addNewAccount
    }

    /// Struct that represents a section in NoActivatedAccountViewController
    public struct Section {
        /// Title of the section
        var title: String
        /// footer of the section
        var footer: String?
        /// list of rows in the section
        var rows: [NoActivatedAccountRowProtocol]
        /// type of the section
        var type: SectionType
    }

    /// Struct that is used to perform an action. Represents a ActionRow in NoActivatedAccountViewController
    public struct ActionRow: NoActivatedAccountRowProtocol {
        /// The row type
        var type: NoActivatedAccountViewModel.RowType
        /// The title of the row.
        var title: String
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock?
    }

    /// Struct that is used to show and interact with a switch. Represents a SwitchRow in NoActivatedAccountViewController
    public struct SwitchRow: NoActivatedAccountRowProtocol {
        /// The row type
        var type: NoActivatedAccountViewModel.RowType
        /// The title of the swith row
        var title: String
        /// Value of the switch
        var isOn: Bool
        /// action to be executed when switch toggle
        var action: SwitchBlock
    }
}

//MARK: - Private

extension NoActivatedAccountViewModel {

    //MARK: - Sections

    private func generateSections() {
        NoActivatedAccountViewModel.SectionType.allCases.forEach { (type) in
            sections.append(sectionForType(sectionType: type))
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

    //MARK: - Rows

    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: The rows. Every one must conform the NoActivatedAccountViewModelRowProtocol.
    private func generateRows(type: SectionType) -> [NoActivatedAccountRowProtocol] {
        var rows = [NoActivatedAccountRowProtocol]()
        switch type {
        case .accounts:
            let inactiveAcccounts = Account.all(onlyActiveAccounts: false).filter({!$0.isActive})
            /// Switch rows
            inactiveAcccounts.forEach { (acc) in
                let accountRow = getSwitchRow(account: acc)
                rows.append(accountRow)
            }

            /// Action rows
            let title = NSLocalizedString("Add account", comment: "No Activated Account - Add account button")
            let actionRow = ActionRow(type: .addNewAccount, title: title) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.delegate?.showAccountSetupView()
            }
            rows.append(actionRow)

            guard inactiveAcccounts.count > 0 else {
                Log.shared.errorAndCrash("There should be at least one inactive account")
                return rows
            }

            return rows
        }
    }

    /// Generate the switch row. 
    /// - Parameter account: The account to generate the row for.
    /// - Returns: The row, already configured.
    private func getSwitchRow(account: Account) -> SwitchRow {
        return SwitchRow(type: .account, title: account.user.address, isOn: false) { [weak self] value in
            //Activate
            account.isActive = true
            account.session.commit()
            //Notify
            NotificationCenter.default.post(name: .pEpSettingsChanged,
                                            object: self,
                                            userInfo: nil)
            //Dismiss
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.delegate?.dismissYourself()
        }
    }
}
