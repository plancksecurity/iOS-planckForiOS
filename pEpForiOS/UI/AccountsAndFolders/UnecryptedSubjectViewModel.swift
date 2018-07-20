//
//  UnecryptedSubjectViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class UnecryptedSubjectViewModel: SettingSwitchProtocol, SettingsCellViewModel  {
    
    var settingCellType: AccountSettingsCellType
    var type: SettingType
    var title : String
    var switchValue : Bool

    init(type: SettingType) {
        self.settingCellType = AccountSettingsCellType.switchOptionCell
        self.type = type
        self.title = NSLocalizedString("Enable Protected Subject", comment: "title for subject protection")
        self.switchValue = !AppSettings.unencryptedSubjectEnabled
    }

    func switchAction(value: Bool) {
        AppSettings.unencryptedSubjectEnabled = !value
    }
}
