//
//  FilterViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 28/03/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class FilterViewModel {

    var sections: [FilterSectionViewModel] = []
    //let inFolder: Bool

    init (inFolder: Bool = false, filter: MessageQueryResultsFilter) {

        if !inFolder {
            sections.append(FilterSectionViewModel(type: .accouts, filter: filter))
        }
        sections.append(FilterSectionViewModel(type: .include, filter: filter))
        sections.append(FilterSectionViewModel(type: .other, filter: filter))
    }

    subscript(index: Int) -> FilterSectionViewModel {
        get {
            guard isValidIndex(index: index) else {
                fatalError("index out of bounds")
            }
            return self.sections[index]
        }
    }
    var count : Int {
        return self.sections.count
    }

    private func isValidIndex(index: Int) -> Bool {
        return index >= 0 && index < sections.count
    }
}


