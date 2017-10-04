//
//  FilterCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class FilterCellViewModel {

    var icon: UIImage?
    var title: String
    var enabled: Bool
    var filter: FilterProtocol

    public init(image: UIImage, title: String, enabled: Bool = false, filter: FilterProtocol) {
        self.icon = image
        self.title = title
        self.enabled = enabled
        self.filter = filter
    }

}
