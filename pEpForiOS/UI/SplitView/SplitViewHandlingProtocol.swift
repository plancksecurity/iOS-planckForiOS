//
//  SplitViewHandlingProtocol.swift
//  pEp
//
//  Created by Xavier Algarra on 28/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Protocol that split View will use to communicate when something will hapen
protocol SplitViewHandlingProtocol {
    /// method called when the split view will change the display status
    /// - Parameter newStatus: the new status
    /// - Parameter SplitViewController: the splitview itself
    func splitViewControllerWill(SplitViewController: PEPSplitViewController, newStatus: SplitViewStatus)
}

/// enum that will be used by splitViewHandling to communicate the dufferent status
public enum SplitViewStatus {
    case collapse
    case separate
}
