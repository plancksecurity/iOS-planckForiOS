//
//  AccountsSettingsCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class AccountsSettingsCellViewModel {
    public enum SettingType {
        case account
        case showLog
        case organizedByThread
        case credits
        case unecryptedSubject
        case defaultAccount
        case keyImport
    }

    var account: Account?
    let type: SettingType
    var status: Bool?

    init(account: Account) {
        self.type = .account
        self.account = account
    }

    init(type: SettingType) {
        self.type = type
        if type == .organizedByThread {
            status = false
        }
    }

    public var title : String? {
        get {
            switch self.type {
            case .showLog:
                return NSLocalizedString("Logging", comment: "")
            case .organizedByThread:
                return NSLocalizedString("Enable Threading", comment: "")
            case .credits:
                return NSLocalizedString("Credits", comment:
                    "AccountsSettings: Cell (button) title to view app credits")
            case .unecryptedSubject:
                return NSLocalizedString("Subject Protection", comment:
                    "AccountsSettings: Cell (button) title to view unencrypted subject setting")
            case .defaultAccount:
                return NSLocalizedString("Default Account", comment:
                    "AccountsSettings: Cell (button) title to view default account setting")
            case .account:
                guard let acc = account else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "Should never be reached")
                    return nil
                }
                return acc.user.address
            case .keyImport:
                return NSLocalizedString("Key import", comment: "AccountSettings: Cell (button) title to start key import setting")
            }
        }
    }

    public var value : String? {
        get {
            switch self.type {
            case .showLog, .account, .credits:
                // Have no value.
                return nil
            case .organizedByThread:
                // Feature unimplemented
                return nil
            case .defaultAccount:
                return AppSettings().defaultAccount
            case .unecryptedSubject:
                return onOffStateString(forState: !AppSettings().unecryptedSubjectEnabled)
            case .keyImport:
                //Have no value
                return nil
            }
        }
    }

    public func delete() {
        self.account?.delete()
    }

    private func onOffStateString(forState enabled: Bool) -> String {
        return enabled
            ? NSLocalizedString("On", comment: "On/Off status of setting")
            : NSLocalizedString("Off", comment: "On/Off status of setting")
    }
}
