//
//  ThreadedSettingViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

struct ThreadedSwitchViewModel: SwitchSettingCellViewModelProtocol  {

    // MARK: - SwitchSettingCellViewModelProtocol

    var cellIdentifier = "switchOptionCell"

    private(set) var title = NSLocalizedString("Thread Messages",
                                           comment: "settings, enable thread view or not")

    func setSwitch(value: Bool) {
        // For now, do nothing, just persist this.
        AppSettings.threadedViewEnabled = value
    }

    func switchValue() -> Bool {
         return AppSettings.threadedViewEnabled
    }
}
