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
    var title: String
    var description: String
    var switchValue: Bool

    init(type: SettingType) {
        self.type = type
        self.settingCellType = .switchOptionCell
        self.title = NSLocalizedString(
            "Thread Messages",
            comment: "settings, enable thread view or not")
        self.description = NSLocalizedString(
            "If enabled, messages in the same thread will be displayed together",
            comment: "explanation for thread view settings")
        self.switchValue = AppSettings.threadedViewEnabled
    }

    func switchAction(value: Bool) {
        AppSettings.threadedViewEnabled = value
        FolderThreading.switchThreading(onOrOff: value)
        NotificationCenter.default.post(name: NSNotification.Name.settingsChanged, object: nil)
    }
}
