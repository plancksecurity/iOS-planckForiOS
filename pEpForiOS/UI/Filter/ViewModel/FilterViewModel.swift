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
    case accouts, include, to, other
}
public class FilterViewModel {

    private var items: [FilterCellViewModel]
    public var title: String

    public init(type: FilterSectionType) {

        items = [FilterCellViewModel]()
        switch type {
        case .accouts:
            self.title = NSLocalizedString("INCLUDE MAIL FROM:", comment: "title for the accounts section")
            break
        case .include:
            self.title = NSLocalizedString("INCLUDE:", comment: "title for the include section")
            break
        case .to:
            self.title = NSLocalizedString("ADDRESSED TO:", comment: "title for the to section")
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
                items.append(FilterCellViewModel(account: account))
            }
            break
        case .include:
            items.append(FilterCellViewModel(type: FilterCellType.unread))
            items.append(FilterCellViewModel(type: FilterCellType.flagged))
            break
        case .to:
            items.append(FilterCellViewModel(type: FilterCellType.forMe))
            items.append(FilterCellViewModel(type: FilterCellType.forMeCc))
            break
        case .other:
            items.append(FilterCellViewModel(type: FilterCellType.attachment))
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


    subscript(index: Int) -> FilterCellViewModel {
        get {
            return self.items[index]
        }
    }
    var count : Int {
        return self.items.count
    }
}
