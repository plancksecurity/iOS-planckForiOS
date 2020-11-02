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

    var currentDisplayMode : SplitViewDisplayMode {
        get {
            guard #available(iOS 13.0, *) else {
                /// Works around a UI glitch:
                /// displayMode in iOS 12 does not update in certain cases.
                /// As Apple doc says: 'Collapsing happens when the split view controller transitions from a horizontally regular to a horizontally compact environment'
                /// In Plus size devices (iPhone 6 Plus, 7 Plus, 8 Plus, iPhone XS Max, iPhone XR) with IOS 12 the isCollapsed property is not updated when rotating from horizontally regular to horizontally compact environment, which leads UI issues that makes the app un-usable.
                /// For more information, please go to https://pep.foundation/jira/browse/IOS-2519.
                return  isIphone && isPortrait ? .onlyMaster : getDisplayMode()
            }
            return getDisplayMode()
        }
    }

    /// value that represent tha actual display mode.
    private func getDisplayMode() -> UISplitViewController.SplitViewDisplayMode {
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
