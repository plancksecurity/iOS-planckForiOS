//
//  PassiveModeViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 09/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import Foundation


class PassiveModeViewModel:SettingSwitchProtocol, SettingsCellViewModelProtocol  {

    var settingCellType: AccountSettingsCellType
    var type: SettingType
    var title : String
    var switchValue : Bool

    init(type: SettingType) {
        self.type = type
        self.settingCellType = .switchOptionCell
        self.title = NSLocalizedString("Enable passive mode", comment: "Passive mode title")
        self.switchValue = AppSettings.passiveMode
    }

    func switchAction(value: Bool) {
        AppSettings.passiveMode = value
    }
}

