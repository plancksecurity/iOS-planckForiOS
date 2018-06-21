//
//  SettingsSwichtViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 20/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

enum settingType {
    case ThreadedViewEnabled
    case UnecryptedSubjectEnabled

}

/*
 static private let keyReinitializePepOnNextStartup = "reinitializePepOnNextStartup"
 static private let keyUnecryptedSubjectEnabled = "unecryptedSubjectEnabled"
 static private let keyDefaultAccountAddress = "keyDefaultAccountAddress"
 static private let keyThreadedViewEnabled
 */

class settingsSwitchViewModel {

    var type : settingType
    var title : String
    var description : String
    var switchValue : Bool

    init(type: settingType) {
        self.type = type
        switch self.type {
        case .ThreadedViewEnabled:
            self.title = "Enable Thread Messages View"
            self.description = "If enabled, messages in the same thread will be displayed together"
            self.switchValue = false

        case .UnecryptedSubjectEnabled:
            self.title = "Enable Protected Subject"
            self.description = "If enabled, message subjects are also protected."
            self.switchValue = false
        }
    }

    func switchAction(Value: Bool) {
        switch type {
        case .ThreadedViewEnabled:
            if Value {

            } else {

            }
            break
        case .UnecryptedSubjectEnabled:
            if Value {

            } else {

            }
            break
        }
    }

}


/*

 Enable Protected Subject

 If enabled, message subjects are also protected.
 */
