//
//  FilterViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public enum FilterSectionType {
    case accouts, include, other
}
public class FilterViewModel {

    private var items: [FilterCellViewModel]
    public var title: String

    public init(type: FilterSectionType, filter: Filter? = nil) {

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

        generateCells(type: type, filter: filter)

    }

    private func generateCells(type: FilterSectionType, filter: Filter? = nil) {
        switch type {
        case .accouts:
            for account in Account.all() {
                items.append(FilterCellViewModel(account: account, filter: filter))
            }
            break
        case .include:
            items.append(FilterCellViewModel(type: .unread, filter: filter))
            items.append(FilterCellViewModel(type: .flagged, filter: filter))
            break
        case .other:
            items.append(FilterCellViewModel(type: .attachment, filter: filter))
            break
        }
    }

    func getFilter() -> Filter {
        let filter = Filter.empty()
        for item in items {
            if let f = item.getFilter(){
                filter.and(filter: f)
            }
        }
        return filter
    }

    func getInvaildFilter() -> Filter {
        let filter = Filter.empty()
        for item in items {
            if let f = item.getInvalidFilter() {
                filter.and(filter: f)
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
