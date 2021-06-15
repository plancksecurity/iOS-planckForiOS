//
//  TrustManagementTableViewCellProtocols.swift
//  pEp
//
//  Created by Martin Brude on 18/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

/// Delegate to notify the events in the cell.
protocol TrustManagementResetTableViewCellDelegate: class {
    /// Delegate method to notify the reset button has been pressed.
    /// - Parameter cell: The cell where the reset button has been pressed
    func resetButtonPressed(on cell: UITableViewCell)
}

/// Delegate to notify the events in the cell.
protocol TrustManagementTableViewCellDelegate: TrustManagementResetTableViewCellDelegate {
    
    /// Delegate method to notify the language button has been pressed.
    /// - Parameter cell: The cell where the language button has been pressed
    func languageButtonPressed(on cell: TrustManagementTableViewCell)
    /// Delegate method to notify the decline button has been pressed.
    /// - Parameter cell: The cell where the decline button has been pressed
    func declineButtonPressed(on cell: TrustManagementTableViewCell)
    /// Delegate method to notify the confirm button has been pressed.
    /// - Parameter cell: The cell where the confirm button has been pressed
    func confirmButtonPressed(on cell: TrustManagementTableViewCell)
    /// Delegate method to notify the trustwords label has been pressed.
    /// - Parameter cell: The cell where the trustwords label has been pressed
    func trustwordsLabelPressed(on cell : TrustManagementTableViewCell)
}
