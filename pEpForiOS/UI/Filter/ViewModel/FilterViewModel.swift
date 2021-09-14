//
//  FilterViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 28/03/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

public class FilterViewModel {
    private var sections: [Section] = []

    public private(set) var filter: MessageQueryResultsFilter
    public var sectionCount : Int {
        return self.sections.count
    }
    private var canDisableAccount: Bool {
        return filter.numEnabledAccounts > 1
    }
    public subscript(index: Int) -> Section {
        get {
            return self.sections[index]
        }
    }

    public init(filter: MessageQueryResultsFilter) {
        self.filter = filter
        resetData()
    }

    public func toggleEnabledState(forRowAt indexPath: IndexPath) {
        var row = sections[indexPath.section][indexPath.row]
        let newState = !row.state

        // ... and create a new filter taking the state change into account
        var mustBeUnread : Bool? = filter.mustBeUnread
        var mustBeFlagged : Bool? = filter.mustBeFlagged
        var mustContainAttachments : Bool? = filter.mustContainAttachments
        var accountsEnabledStates = filter.accountsEnabledStates
        switch row.type {
        case .account:
            guard isOkToAlterAccountsEnabledState(with: newState) else {
                return
            }
            guard let account = filter.account(at: indexPath.row) else {
                Log.shared.errorAndCrash("No Account for row")
                return
            }
            accountsEnabledStates[indexPath.row] = [account: newState]
        case .flagg:
            if !newState {
                mustBeFlagged = nil
            } else {
                mustBeFlagged = newState
            }
        case .unread:
            if !newState {
                mustBeUnread = nil
            } else {
                mustBeUnread = newState
            }
        case .attachments:
            if !newState {
                mustContainAttachments = nil
            } else {
                mustContainAttachments = newState
            }
        }
        // Set new state in UI data source ...
        row.state = newState
        sections[indexPath.section][indexPath.row].state = newState

        filter = MessageQueryResultsFilter(mustBeFlagged: mustBeFlagged,
                                           mustBeUnread: mustBeUnread,
                                           mustContainAttachments: mustContainAttachments,
                                           accountEnabledStates: accountsEnabledStates)
    }
}

// MARK: - Private

extension FilterViewModel {
    private func resetData() {
        sections = []
        generateSection(type: .accouts)
        generateSection(type: .include)
        generateSection(type: .other)
    }

    private func generateSection(type: SectionType) {
        switch type {

        case .accouts:
            guard filter.accounts.count >= 2 else {
                // We show the accounts section only if there are multiple accounts.
                // Example: UnifiedInbox
                return
            }
            let sectionType = SectionType.accouts
            let rows: [Row] = filter.accountsEnabledStates.compactMap {
                let rowType = RowType.account
                guard let accountEnabledState = $0.first else {
                    Log.shared.errorAndCrash("No Account state")
                    return nil
                }
                return createRow(type: rowType , account: accountEnabledState.key,
                                 state: accountEnabledState.value)
            }
            let section = Section(type: sectionType, title: sectionType.localizedTitle, rows: rows)
            sections.append(section)

        case .include:
            let sectionType = SectionType.include

            var rows = [Row]()
            var rowType = RowType.unread
            var nextRow = createRow(type: rowType,
                                    state: filter.mustBeUnread ?? rowType.defaultState())
            rows.append(nextRow)

            rowType = RowType.flagg
            nextRow = createRow(type: rowType ,
                                state: filter.mustBeFlagged ?? rowType.defaultState())
            rows.append(nextRow)

            let section = Section(type: sectionType, title: sectionType.localizedTitle, rows: rows)
            sections.append(section)

        case .other:
            let sectionType = SectionType.other
            var rows = [Row]()
            let rowType = RowType.attachments
            let nextRow = createRow(type: rowType,
                                    state: filter.mustContainAttachments ?? rowType.defaultState())
            rows.append(nextRow)

            let section = Section(type: sectionType, title: sectionType.localizedTitle, rows: rows)
            sections.append(section)
        }
    }

    private func createRow(type: RowType, account: Account? = nil, state: Bool) -> Row {
        let title = rowTitel(type: type, account: account)
        return Row(type: type, title: title, state: state)
    }

    private func rowTitel(type: RowType, account: Account? = nil) -> String {
        switch type {
        case .account:
            guard let accountAddress = account?.user.address else {
                Log.shared.errorAndCrash("Error generating row")
                return ""
            }
            return accountAddress
        case .attachments:
            return NSLocalizedString("Attachments", comment: "title attachments filter cell")
        case .flagg:
            return NSLocalizedString("Flagged", comment: "title unread filter cell")
        case .unread:
            return NSLocalizedString("Unread", comment: "title unread filter cell")
        }
    }
}

extension FilterViewModel {
    enum SectionType {
        case accouts, include, other

        var localizedTitle: String {
            switch self {
            case .accouts:
                return NSLocalizedString("INCLUDE MAIL FROM:",
                                         comment: "title for the accounts section")
            case .include:
                return NSLocalizedString("INCLUDE:",
                                         comment: "title for the include section")
            case .other:
                //!!!: I have invented this title (no one existed in code). Please set it to what it was before refactoring, or what design specifies
                return NSLocalizedString("OTHER:",
                                         comment: "title for the attachment section")            }
        }
    }

    public struct Section {
        let type: SectionType
        let title: String
        fileprivate(set) var rows: [Row]

        var count : Int {
            return rows.count
        }

        subscript(index: Int) -> Row {
            get {
                return rows[index]
            }
            set {
                rows[index] = newValue
            }
        }
    }

    enum RowType {
        case account, flagg, unread, attachments

        func defaultState() -> Bool {
            switch self {
            case .account:
                return true
            case .flagg:
                return false
            case .unread:
                return false
            case .attachments:
                return false
            }
        }

        var icon: UIImage {
            switch self {
            case .account:
                return UIImage(named: "folders-icon-inbox")!
            case .attachments:
                return UIImage(named: "attachment-list-icon")!
            case .flagg:
                return UIImage(named: "icon-flagged")!
            case .unread:
                return UIImage(named: "icon-unread")!
            }
        }
    }

    struct Row {
        let type: RowType
        let title: String
        fileprivate(set) var state: Bool

        var icon: UIImage {
            return type.icon
        }
    }
}

// MARK: - Convenience

extension FilterViewModel {

    /// We do not allow to disable all accounts (as the result would always be zero mails)
    private func isOkToAlterAccountsEnabledState(with newState: Bool) -> Bool {
        let isDisable = newState == false
        if isDisable {
            guard canDisableAccount else {
                return false
            }
        }
        return true
    }
}
