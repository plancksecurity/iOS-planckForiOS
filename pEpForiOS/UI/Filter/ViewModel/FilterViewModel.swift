//
//  FilterViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

public enum FilterSectionType {
    case accouts, include, other
}
public class FilterViewModel {
    private var items: [FilterCellViewModel]
    public var title: String
    public var filters: MessageQueryResultsFilter?

    public init(type: FilterSectionType, filter: MessageQueryResultsFilter? = nil) {
        if let previousFilter = filter {
            filters = previousFilter
        }
        items = [FilterCellViewModel]()
        switch type {
        case .accouts:
            self.title = NSLocalizedString("INCLUDE MAIL FROM:", comment: "title for the accounts section")
            break
        case .include:
            self.title = NSLocalizedString("INCLUDE:", comment: "title for the include section")
            break
        case .other:
            self.title = ""
            break
        }
        generateCells(type: type)
    }

    private func generateCells(type: FilterSectionType) {
        switch type {
        case .accouts:
            for account in Account.all() {
                guard let icon = UIImage(named: "folders-icon-inbox") else {
                    Logger.frontendLogger.errorAndCrash("Error Loading images")
                    return
                }
                items.append(
                    FilterCellViewModel(image: icon, title: account.user.address,
                                        enabled: filters?.accounts.contains(account), type: .Account))
            }
            break
        case .include:
            guard let unreadIcon = UIImage(named: "icon-unread") else {
                Logger.frontendLogger.errorAndCrash("Error Loading images")
                return
            }
            items.append(
                FilterCellViewModel(image: unreadIcon,
                                    title: NSLocalizedString("Unread",
                                                             comment: "title unread filter cell"),
                                    enabled: filters?.mustBeUnread, type: .Unread))

            guard let flaggedIcon = UIImage(named: "icon-flagged") else {
                Logger.frontendLogger.errorAndCrash("Error Loading images")
                return
            }
            items.append(
                FilterCellViewModel(image: flaggedIcon,
                                    title: NSLocalizedString("Flagged",
                                                             comment: "title unread filter cell"),
                                    enabled: filters?.mustBeFlagged, type: .Flagg))
            break
        case .other:
            guard let attachIcon = UIImage(named: "attachment-list-icon") else {
                Logger.frontendLogger.errorAndCrash("Error Loading images")
                return
            }
            items.append(
                FilterCellViewModel(image: attachIcon,
                                    title: NSLocalizedString("Attachments",
                                                             comment: "title attachments filter cell"),
                                    enabled: filters?.mustContainAttachments, type: .Attachments))
            break
        }
    }

    func getFilters() -> MessageQueryResultsFilter {

        var flagged: Bool? = nil
        var unread: Bool? = nil
        var attachments: Bool? = nil
        var accounts: [Account] = []
        for item in items {
            switch item.filterType {
            case .Account:
                //!!!: accounts must be rethink
                break;
            case .Attachments:
                attachments = item.enabled
            case .Flagg:
                flagged = item.enabled
            case .Unread:
                unread = item.enabled
            }
        }
        let filter = MessageQueryResultsFilter(mustBeFlagged: flagged, mustBeUnread: unread, mustContainAttachments: attachments, accounts: accounts)
        return filter
    }

    func accountsEnabled() -> Int {
        var accountsSelected = 0
        for filter in items {
            if(filter.enabled) {
                accountsSelected += 1
            }
        }
        return accountsSelected
    }

    @available(*, deprecated)
    func getInvalidFilters() -> CompositeFilter<FilterBase> {
        let filter = CompositeFilter<FilterBase>()
        for item in items {
            if !item.enabled {
                //filter.add(filter: item.filter)
            }
        }
        return filter
    }

    subscript(index: Int) -> FilterCellViewModel {
        get {
            return self.items[index]
        }
    }
    var count : Int {
        return self.items.count
    }
}

