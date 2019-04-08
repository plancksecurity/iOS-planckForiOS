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
    }

    enum RowType {
        case account, flagg, unread, attachments
    }

    struct Section {
        let type: SectionType
        let title: String
        var rows: [Row]

        var count : Int {
            return rows.count
        }

        private func isValidIndex(index: Int) -> Bool {
            return index >= 0 && index < rows.count
        }

        subscript(index: Int) -> Row {
            get {
                guard isValidIndex(index: index) else {
                    fatalError("index out of bounds")
                }
                return rows[index]
            }
        }
    }

    struct Row {
        let type: RowType
        let title: String
        let icon: UIImage
        var state: Bool
    }
}

public class FilterViewModel {
    let filter: MessageQueryResultsFilter

    var sections: [Section] = []

    init(filter: MessageQueryResultsFilter) {
        self.filter = filter
        generateStructure()
    }

    var count : Int {
        return self.sections.count
    }

    private func isValidIndex(index: Int) -> Bool {
        return index >= 0 && index < sections.count
    }

    subscript(index: Int) -> Section {
        get {
            guard isValidIndex(index: index) else {
                fatalError("index out of bounds")
            }
                return self.sections[index]
        }
    }

    private func generateStructure() {
        if filter.accounts.count > 1 {
            generateSection(type: .accouts)
        }
        generateSection(type: .include)
        generateSection(type: .other)
    }

    private func generateSection(type: SectionType) {
        switch type {
        case .accouts:
            var accountRow: [Row] = []
            for item in filter.accounts {
                guard let row = createRow(type: .account , account: item, state: true) else {
                    return
                }
                accountRow.append(row)
            }
            let title = NSLocalizedString("INCLUDE MAIL FROM:", comment: "title for the accounts section")
            let section = Section(type: .accouts, title: title, rows: accountRow)
            sections.append(section)
            break
        case .include:
            //self.title = NSLocalizedString("INCLUDE:", comment: "title for the include section")
            //TODO: Not yet implemented
            break
        case .other:
            //TODO: Not yet implemented
            //self.title = ""
            break
        }
    }

    private func createRow(type: RowType, account: Account?, state: Bool) -> Row? {
        guard let icon = getIconRow(type: type) else {
            Logger.frontendLogger.errorAndCrash("Error generating row")
            return nil
        }
        let title = getTitleRow(type: type, account: account)
        return Row(type: type, title: title, icon: icon, state: state)
    }

    func getTitleRow(type: RowType, account: Account? = nil) -> String {
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

    func getIconRow(type: RowType) -> UIImage? {
        switch type {
        case .account:
            guard let icon = UIImage(named: "folders-icon-inbox" ) else {
                Logger.frontendLogger.errorAndCrash("Error Loading images")
                return nil
            }
            return icon
        case .attachments:
            guard let icon = UIImage(named: "attachment-list-icon" ) else {
                Logger.frontendLogger.errorAndCrash("Error Loading images")
                return nil
            }
            return icon
        case .flagg:
            guard let icon = UIImage(named: "icon-flagged" ) else {
                Logger.frontendLogger.errorAndCrash("Error Loading images")
                return nil
            }
            return icon
        case .unread:
            guard let icon = UIImage(named: "icon-unread" ) else {
                Logger.frontendLogger.errorAndCrash("Error Loading images")
                return nil
            }
            return icon
        }
    }
}


