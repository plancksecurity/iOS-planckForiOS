//
//  SplitViewHandlingProtocol.swift
//  pEp
//
//  Created by Xavier Algarra on 28/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Protocol that split View will use to communicate when something will happen
protocol SplitViewHandlingProtocol {
    /// method called when the split view will change the display status to allow the controllers prepare for it.
    /// - Parameter newStatus: the new status 
    /// - Parameter splitViewController: the splitview itself
    func splitViewControllerWill(splitViewController: PEPSplitViewController, newStatus: SplitViewStatus)
}

/// Protocol that split view uses to choose the behavior when collapse or separate will happen.
@objc protocol SplitViewControllerBehaviorProtocol {
    /// Attribute that can be overwritten with the default behaviour of the splitview when this will collapse
    /// Split view expect to find this attribute in the controller that will be collapsed,
    /// and will use its value to decide the Behavior on collapse action of this view.
    var collapsedBehavior: CollapsedSplitViewBehavior { get }
    
    /// Attribute that can be overwritten with the default behaviour of the splitview when this will separate
    /// Split view expect to find this attribute in the controller that will be separated,
    /// and will use its value to decide the Behavior on separate action of this view.
    var separatedBehavior: SeparatedSplitViewBehavior { get }
}

/// enum that will be used by splitViewHandling to communicate the state of the splitview when joining or separeting
public enum SplitViewStatus {
    case collapse
    case separate
}

/// Options availabe when the splitView will collapse
@objc public enum CollapsedSplitViewBehavior: Int {
    /// Use this when the view should be disposed and not moved to the master view controller
    case disposable = 0
    /// Use thiw when the view should be keepd and moved to the master view controller
    case needed = 1
}

/// Options availabe when the splitView will separate
@objc public enum SeparatedSplitViewBehavior: Int {
    /// Use this when the view should stay in the master view controller
    case master = 0
    /// Use this when the view should be moved to the detail view controller
    case detail = 1
}
