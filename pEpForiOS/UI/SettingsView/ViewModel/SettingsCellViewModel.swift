//
//  SettingsCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension SettingsCellViewModel {
    public enum SettingType {
        case account
        case showLog
        case credits
        case defaultAccount
    }
}

/// Cell for settings that are not only one on/off switch.
public class SettingsCellViewModel: ComplexSettingCellViewModelProtocol { //IOS-1250: rename!
    var cellIdentifier = "accountsCell" //IOS-1250 rename cell ID
    
    var type: SettingType
    var account: Account?
    var status: Bool?

    init(account: Account) {
        self.type = .account
        self.account = account
    }

    init(type: SettingType) {
        self.type = type
    }

    public var detail : String? {
        get {
            switch self.type {
            case .defaultAccount:
                return AppSettings.defaultAccount
            default:
                return nil
            }
        }
    }

    public var title : String? {
        get {
            switch self.type {
            case .showLog:
                return NSLocalizedString("Logging", comment: "")
            case .credits:
                return NSLocalizedString(
                    "Credits",
                    comment: "AccountsSettings: Cell (button) title to view app credits")
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
            }
        }
    }

    public var value : String? {
        get {
            switch self.type {
            case .showLog, .account, .credits:
                // Have no value.
                return nil
            case .defaultAccount:
                return AppSettings.defaultAccount
            }
        }
    }

    public func delete() {
        self.account?.delete()
    }
}
