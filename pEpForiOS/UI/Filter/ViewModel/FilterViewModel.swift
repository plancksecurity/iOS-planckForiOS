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
                return NSLocalizedString("OTHER:",  //!!!: I have invented this title (no one existed in code). Please set it to what it was before refactoring
                    comment: "title for the attachment section")            }
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
                return true
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

    struct Section {
        let type: SectionType
        let title: String
        var rows: [Row]

        var count : Int {
            return rows.count
        }

        subscript(index: Int) -> Row {
            get {
                return rows[index]
            }
        }
    }

    struct Row {
        let type: RowType
        let title: String
        var state: Bool

        var icon: UIImage {
            return type.icon
        }

    }
}

public struct FilterViewModel {
    //!!!:this filter could be modified.
    private let filter: MessageQueryResultsFilter
    private var sections: [Section] = []

    init(filter: MessageQueryResultsFilter) {
        self.filter = filter
        resetData()
    }

    var count : Int {
        return self.sections.count
    }

    subscript(index: Int) -> Section {
        get {
            return self.sections[index]
        }
    }

    mutating private func resetData() {
        sections = []
        generateSection(type: .accouts)
        generateSection(type: .include)
        generateSection(type: .other)
    }

    mutating private func generateSection(type: SectionType) {
        switch type {

        case .accouts:
            guard filter.accounts.count >= 2 else {
                // We show the accounts section only if there are multiple accounts.
                // Example: UnifiedInbox
                return
            }
            let sectionType = SectionType.accouts
            let rows: [Row] = filter.accounts.map {
                let rowType = RowType.account
                return createRow(type: rowType , account: $0, state: rowType.defaultState())
            }
            let section = Section(type: sectionType, title: sectionType.localizedTitle, rows: rows)
            sections.append(section)

        case .include:
            let sectionType = SectionType.include

            var rows = [Row]()
            var rowType = RowType.unread
            var nextRow = createRow(type: rowType, state: rowType.defaultState())
            rows.append(nextRow)

            rowType = RowType.flagg
            nextRow = createRow(type: rowType , state: rowType.defaultState())
            rows.append(nextRow)

            let section = Section(type: sectionType, title: sectionType.localizedTitle, rows: rows)
            sections.append(section)

        case .other:
            let sectionType = SectionType.other
            var rows = [Row]()
            let rowType = RowType.attachments
            let nextRow = createRow(type: rowType, state: rowType.defaultState())
            rows.append(nextRow)

            let section = Section(type: sectionType, title: sectionType.localizedTitle, rows: rows)
            sections.append(section)
        }
    }

    private func createRow(type: RowType, account: Account? = nil, state: Bool) -> Row {
        let title = rowTitel(type: type, account: account)
        return Row(type: type, title: title, state: state)
    }

    func rowTitel(type: RowType, account: Account? = nil) -> String {
        switch type {
        case .account:
            guard let accountAddress = account?.user.address else {
                Logger.frontendLogger.errorAndCrash("Error generating row")
                //!!!: it is posible to get in there?
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


