//
//  UnecryptedSubjectViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class UnecryptedSubjectViewModel: SettingSwitchProtocol  {

    var title : String
    var description : String
    var switchValue : Bool

    init() {
        self.title = "Enable Protected Subject"
        self.description = "If enabled, message subjects are also protected."
        self.switchValue = !AppSettings.init().unencryptedSubjectEnabled
    }

    func switchAction(value: Bool) {
        AppSettings.init().unencryptedSubjectEnabled = !value
    }
}
