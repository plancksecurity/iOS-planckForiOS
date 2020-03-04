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
    /// method called when the split view will change the display status
    /// - Parameter newStatus: the new status 
    /// - Parameter splitViewController: the splitview itself
    func splitViewControllerWill(splitViewController: PEPSplitViewController, newStatus: SplitViewStatus)
}

@objc protocol SplitViewControllerBehaviorProtocol {
    /// Attribute that can be overwritten with the default behaviour of the splitview when  this will collapse
    var collapsedBehavior: CollapsedSplitViewBehavior { get }
    
    /// Attribute that can be overwritten with the default behaviour of the splitview when this will separate
    var separatedBehavior: SeparatedSplitViewBehavior { get }
}

/// enum that will be used by splitViewHandling to communicate the dufferent status
public enum SplitViewStatus {
    case collapse
    case separate
}

/// Options availabe when the splitView will collapse
@objc public enum CollapsedSplitViewBehavior: Int {
    case disposable = 0
    case needed = 1
}

/// Options availabe when the splitView will separate
@objc public enum SeparatedSplitViewBehavior: Int {
    case master = 0
    case detail = 1
}
