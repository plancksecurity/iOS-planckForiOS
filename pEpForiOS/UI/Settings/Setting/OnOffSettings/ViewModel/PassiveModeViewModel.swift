//
//  PassiveModeViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 09/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

struct PassiveModeViewModel: SwitchSettingCellViewModelProtocol  {

    // MARK: - SwitchSettingCellViewModelProtocol

    var cellIdentifier = "switchOptionCell"

    private(set) var title = NSLocalizedString("Enable passive mode", comment: "Passive mode title")

    func setSwitch(value: Bool) {
        AppSettings.passiveMode = value
    }

    func switchValue() -> Bool {
        return AppSettings.passiveMode
    }
}
