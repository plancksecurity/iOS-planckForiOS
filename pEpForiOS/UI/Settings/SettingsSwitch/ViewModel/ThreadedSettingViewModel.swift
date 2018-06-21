//
//  ThreadedSettingViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation


class ThreadedSwitchViewModel:SettingSwitchProtocol  {

    var title : String
    var description : String
    var switchValue : Bool

    init() {
        self.title = "Enable Thread Messages View"
        self.description = "If enabled, messages in the same thread will be displayed together"
        self.switchValue = AppSettings.init().threadedViewEnabled
    }

    func switchAction(value: Bool) {
        AppSettings.init().threadedViewEnabled = value
    }
}

