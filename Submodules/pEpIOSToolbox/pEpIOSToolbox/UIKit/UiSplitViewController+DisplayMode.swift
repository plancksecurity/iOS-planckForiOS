//
//  UiSplitViewController+DisplayMode.swift
//  pEpIOSToolbox
//
//  Created by Xavier Algarra on 15/10/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

public extension UISplitViewController {

    /// Specify the current state of the splitviewcontroller
    ///
    /// - onlyMaster: value when only primary view controller is displayed
    /// - masterAndDetail: value when master and detail is displayed
    /// - onlyDetail: value when only detail is displayed
    enum SplitViewDisplayMode {
        case onlyMaster
        case masterAndDetail
        case onlyDetail
    }

    /// value that represent tha actual display mode.
    var currentDisplayMode : SplitViewDisplayMode {
        get {
            if isCollapsed {
                return .onlyMaster
            } else {
                switch displayMode {
                case .automatic:
                    //this case is never posible as splitviewcontroller.displaymode never will return that
                    return .onlyMaster
                case .secondaryOnly:
                    return .onlyDetail
                case .oneOverSecondary,
                     .oneBesideSecondary,
                     .twoOverSecondary,
                     .twoDisplaceSecondary,
                     .twoBesideSecondary:
                    return .masterAndDetail
                @unknown default:
                    //this case is because apple do not assures other posible cases for displayMode.
                    return .onlyMaster
                }
            }
        }
    }
}
