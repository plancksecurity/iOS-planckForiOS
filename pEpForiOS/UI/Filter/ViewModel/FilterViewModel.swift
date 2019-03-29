//
//  FilterViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 28/03/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

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
        let rows: [Row]
    }

    struct Row {
        let type: RowType
        let title: String
        let icon: UIImage
        let state: Bool
    }
}

public class FilterViewModel {
    let filter: MessageQueryResultsFilter



    let sections: [Section]

    init(filter: MessageQueryResultsFilter) {
        self.filter = filter
    }

//
//
//
//    let filter : MessageQueryResultsFilter
//
//    init (inFolder: Bool = false, filter: MessageQueryResultsFilter) {
//
//        if !inFolder {
//            sections.append(FilterSectionViewModel(type: .accouts, filter: filter))
//        }
//        sections.append(FilterSectionViewModel(type: .include, filter: filter))
//        sections.append(FilterSectionViewModel(type: .other, filter: filter))
//    }
//
//    subscript(index: Int) -> FilterSectionViewModel {
//        get {
//            guard isValidIndex(index: index) else {
//                fatalError("index out of bounds")
//            }
//            return self.sections[index]
//        }
//    }
//
//    private func getFlagValue() -> Bool {
//        var flaggValue : Bool = false
//        for item in sections {
//            if let value = item.getFlagValue() {
//                flaggValue = value
//            }
//        }
//        return flaggValue
//    }
//
//    private func getUnreadValue() -> Bool {
//        var unreadValue : Bool = false
//        for item in sections {
//            if let value = item.getUnreadValue() {
//                unreadValue = value
//            }
//        }
//        return unreadValue
//    }
//
//    private func getAttachmentsValue() -> Bool {
//        var AttachmentsValue : Bool = false
//        for item in sections {
//            if let value = item.getFlagValue() {
//                AttachmentsValue = value
//            }
//        }
//        return AttachmentsValue
//    }
//
//    private func getAccountsValue() -> [Account] {
//        return []
//    }
//
//    public func getFilters() -> MessageQueryResultsFilter {
//        return MessageQueryResultsFilter(mustBeFlagged: getFlagValue(), mustBeUnread: getUnreadValue(), mustContainAttachments: getAttachmentsValue(), accounts: [])
//    }
//
//    var count : Int {
//        return self.sections.count
//    }
//
//    private func isValidIndex(index: Int) -> Bool {
//        return index >= 0 && index < sections.count
//    }
}


