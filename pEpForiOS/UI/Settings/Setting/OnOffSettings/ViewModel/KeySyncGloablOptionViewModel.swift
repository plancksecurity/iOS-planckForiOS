//
//  KeySyncGloablOptionViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 27/05/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

struct KeySyncGloablOptionViewModel: SwitchSettingCellViewModelProtocol {

    var cellIdentifier = "switchOptionCell"

    private(set) var title = NSLocalizedString("Keysync", comment: "Enabling disabing keysync")

    func setSwitch(value: Bool) {
        AppSettings.keySyncGlobal = value
    }

    func switchValue() -> Bool {
        return AppSettings.keySyncGlobal
    }

}
