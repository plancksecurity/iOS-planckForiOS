//
//  UnecryptedSubjectViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class UnecryptedSubjectViewModel: SettingSwitchProtocol, SettingsCellViewModelProtocol  {

    var settingCellType: SettingsCellViewModel.CellType
    var type: SettingsCellViewModel.SettingType
    var title : String
    var switchValue : Bool

    init(type: SettingsCellViewModel.SettingType) {
        self.settingCellType = SettingsCellViewModel.CellType.switchOptionCell
        self.type = type
        self.title = NSLocalizedString("Enable Protected Subject",
                                       comment: "title for subject protection")
        self.switchValue = !AppSettings.unencryptedSubjectEnabled
    }

    func switchAction(value: Bool) {
        AppSettings.unencryptedSubjectEnabled = !value
    }
}
