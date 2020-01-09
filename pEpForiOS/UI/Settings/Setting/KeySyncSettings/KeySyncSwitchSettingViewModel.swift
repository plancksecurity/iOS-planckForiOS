//
//  KeySyncSwitchSetting.swift
//  pEp
//
//  Created by Xavier Algarra on 09/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

struct KeySyncSwitchViewModel: SwitchSettingCellViewModelProtocol  {

    // MARK: - SwitchSettingCellViewModelProtocol

    var cellIdentifier = "switchOptionCell"

    private(set) var title = NSLocalizedString("p≡p Sync", comment: "pep sync title")

    func setSwitch(value: Bool) {
        //missing switch action
    }

    func switchValue() -> Bool {
        return AppSettings.shared.passiveMode
    }
}

