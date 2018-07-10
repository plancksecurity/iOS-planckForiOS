//
//  ThreadedSettingViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation


class ThreadedSwitchViewModel:SettingSwitchProtocol, SettingsCellViewModel  {
    var settingCellType: AccountSettingsCellType
    var type: SettingType
    var title : String
    var description : String
    var switchValue : Bool

    init(type: SettingType) {
        self.type = type
        self.settingCellType = .switchOptionCell
        self.title = "Enable Thread Messages View"
        self.description = "If enabled, messages in the same thread will be displayed together"
        self.switchValue = AppSettings.init().threadedViewEnabled
    }

    func switchAction(value: Bool) {
        AppSettings.init().threadedViewEnabled = value
        FolderThreading.switchThreading(onOrOff: value)
    }
}

