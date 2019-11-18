//
//  EnableKeySyncViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 19/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

struct EnableKeySyncViewModel: SwitchSettingCellViewModelProtocol  {

    // MARK: - SwitchSettingCellViewModelProtocol

    var cellIdentifier = "switchOptionCell"
    private(set) var title = NSLocalizedString("Enable p≡p Sync",
                                               comment: "enable p≡p Sync with other devices in the group")


    func setSwitch(value: Bool) {
        AppSettings.shared.keySyncEnabled = value
    }

    func switchValue() -> Bool {
        return AppSettings.shared.keySyncEnabled
    }
}
