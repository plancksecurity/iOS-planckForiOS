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
    /// <#Description#>
    /// - Parameter newStatus: <#newStatus description#>
    func splitViewControllerWill(SplitViewController: PEPSplitViewController, newStatus: SplitViewStatus)
}

public enum SplitViewStatus {
    case collapse
    case separate
}
