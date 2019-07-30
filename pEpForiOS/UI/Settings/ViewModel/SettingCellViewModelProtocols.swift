//
//  SettingsSwichtViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 20/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Simple settings cell that offers an ON/OFF switch only
protocol SwitchSettingCellViewModelProtocol: SettingCellViewModelProtocol {
    // Title of setting to display to user
    var title: String { get }

    /// HAndles switch changes
    /// - Parameter value: switch value to handle
    func setSwitch(value: Bool)

    /// - Returns: Current value of the switch
    func switchValue() -> Bool
}

/// Rather complex settings cell that offers more than a simple ON/OFF switch only
protocol ComplexSettingCellViewModelProtocol: SettingCellViewModelProtocol {
    var type : SettingsCellViewModel.SettingType { get }
}

protocol SettingsActionCellViewModelProtocol: SettingCellViewModelProtocol {
    var type: SettingsActionCellViewModel.ActionCellType { get }
}

/// Common identifier
protocol SettingCellViewModelProtocol {
    var cellIdentifier: String { get }
}
