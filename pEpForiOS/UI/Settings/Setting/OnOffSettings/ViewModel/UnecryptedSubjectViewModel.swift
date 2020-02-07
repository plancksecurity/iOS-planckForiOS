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

    private(set) var title = NSLocalizedString("Protect Message Subject",
                                           comment: "title for subject protection")
    func setSwitch(value: Bool) {
        AppSettings.shared.unencryptedSubjectEnabled = !value
    }

    var switchValue: Bool {
        return !AppSettings.shared.unencryptedSubjectEnabled
    }
}
