//
//  UnecryptedSubjectViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

struct UnecryptedSubjectViewModel: SwitchSettingCellViewModelProtocol  {

    // MARK: - SwitchSettingCellViewModelProtocol

    var cellIdentifier = "switchOptionCell"

    private(set) var title = NSLocalizedString("Enable Protected Subject",
                                           comment: "title for subject protection")
    func setSwitch(value: Bool) {
        AppSettings.unencryptedSubjectEnabled = !value
    }

    func switchValue() -> Bool {
        return !AppSettings.unencryptedSubjectEnabled
    }
}
