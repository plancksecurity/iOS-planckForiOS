//
//  FilterViewDelegate.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 17/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public protocol FilterViewDelegate {
    func filterChanged(newFilter: MessageQueryResultsFilter)
}
