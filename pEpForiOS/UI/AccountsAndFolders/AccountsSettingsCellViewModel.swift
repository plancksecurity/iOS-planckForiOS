//
//  AccountsSettingsCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public enum AccountSettingsCellType: String {
    case accountsCell = "accountsCell"
    case switchOptionCell = "switchOptionCell"

    func isAccountCell() -> Bool {
        return self == AccountSettingsCellType.accountsCell
    }

    func isSwitchOptionCell() -> Bool {
        return self == AccountSettingsCellType.switchOptionCell
    }

}
public enum SettingType {
    case account
    case showLog
    case organizedByThread
    case credits
    case unecryptedSubject
    case pasiveMode
    case defaultAccount
}

public class AccountsSettingsCellViewModel: SettingsCellViewModel {

    var settingCellType: AccountSettingsCellType
    var type: SettingType
    var account: Account?
    var status: Bool?

    init(account: Account) {
        self.type = .account
        self.account = account
        self.settingCellType = .accountsCell
    }

    init(type: SettingType) {
        self.type = type
        switch self.type {
        case .account, .credits, .defaultAccount, .showLog:
            self.settingCellType = AccountSettingsCellType.accountsCell
        case .organizedByThread, .unecryptedSubject, .pasiveMode:
            self.settingCellType = AccountSettingsCellType.switchOptionCell
        }
    }

    public var detail : String? {
        get {
            switch self.type {
            case .defaultAccount:
                return AppSettings.init().defaultAccount
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
            case .organizedByThread:
                return NSLocalizedString(
                    "Enable Threading Messages",
                    comment: "AccountsSettings: Cell (button) title to view threads messages together")
            case .credits:
                return NSLocalizedString(
                    "Credits",
                    comment: "AccountsSettings: Cell (button) title to view app credits")
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

            case .pasiveMode:
                return "pasive mode"//TODO

            }
        }
    }

    public var value : String? {
        get {
            switch self.type {
            case .showLog, .account, .credits:
                // Have no value.
                return nil
            case .pasiveMode:
                return onOffStateString(forState: false) //TODO
            case .organizedByThread:
                return onOffStateString(forState: AppSettings().threadedViewEnabled)
            case .defaultAccount:
                return AppSettings().defaultAccount
            case .unecryptedSubject:
                return onOffStateString(forState: !AppSettings().unencryptedSubjectEnabled)
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
