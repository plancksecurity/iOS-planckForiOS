//
//  UiSplitViewController+DisplayMode.swift
//  pEpIOSToolbox
//
//  Created by Xavier Algarra on 15/10/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {

    /// Method to detect the actual status of the splitViewController
    ///
    /// - Returns: returns the value of the actual status of the split view controller using SplitViewDisplayMode
    func currentSplitViewMode() -> UISplitViewController.SplitViewDisplayMode {
        guard let splitview = splitViewController else {
            return .onlyMaster
        }
        return splitview.currentDisplayMode
    }

    var onlySplitViewMasterIsShown: Bool {
        get {
            return currentSplitViewMode() == .onlyMaster
        }
    }
}

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
                case .allVisible, .primaryOverlay:
                    return .masterAndDetail
                case .primaryHidden:
                    return .onlyDetail
                case .automatic:
                    //this case is never posible as splitviewcontroller.displaymode never will return that
                    return .onlyMaster
                @unknown default:
                    //this case is because apple do not assures other posible cases for displayMode.
                    return .onlyMaster
                }
            }
        }
    }
}
