//
//  PassiveModeViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 09/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import Foundation


class PassiveModeViewModel:SettingSwitchProtocol, SettingsCellViewModel  {

    var settingCellType: AccountSettingsCellType
    var type: SettingType
    var title : String
    var description : String
    var switchValue : Bool

    init(type: SettingType) {
        self.type = type
        self.settingCellType = .switchOptionCell
        self.title = "Enable passive mode"
        self.description = "" //TODO
        self.switchValue = false //TODO
    }

    func switchAction(value: Bool) {
        //TODO
    }
}

