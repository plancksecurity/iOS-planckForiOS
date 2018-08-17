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
    public enum CellType: String {
        case accountsCell = "accountsCell"
        case switchOptionCell = "switchOptionCell"

        func isAccountCell() -> Bool {
            return self == CellType.accountsCell
        }

        func isSwitchOptionCell() -> Bool {
            return self == CellType.switchOptionCell
        }
    }

    public enum SettingType {
        case account
        case showLog
        case organizedByThread
        case credits
        case unecryptedSubject
        case passiveMode
        case defaultAccount
    }
}

public class SettingsCellViewModel: SettingsCellViewModelProtocol {

    var settingCellType: CellType
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
            self.settingCellType =
                CellType.accountsCell
        case .organizedByThread, .unecryptedSubject, .passiveMode:
            self.settingCellType = CellType.switchOptionCell
        }
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

            case .passiveMode:
                return "passive mode"//TODO

            }
        }
    }

    public var value : String? {
        get {
            switch self.type {
            case .showLog, .account, .credits:
                // Have no value.
                return nil
            case .passiveMode:
                return onOffStateString(forState: false) //TODO
            case .organizedByThread:
                return onOffStateString(forState: AppSettings.threadedViewEnabled)
            case .defaultAccount:
                return AppSettings.defaultAccount
            case .unecryptedSubject:
                return onOffStateString(forState: !AppSettings.unencryptedSubjectEnabled)
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
