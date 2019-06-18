//
//  ActionCellViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 17/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//
import Foundation
import MessageModel
import pEpIOSToolbox

extension SettingsActionCellViewModel {
    enum ActionCellType {
        case leaveKeySyncGroup
    }
}

/// Cell for settings that are not only one on/off switch.
final class SettingsActionCellViewModel: SettingsActionCellViewModelProtocol {
    var cellIdentifier = "SettingsActionCell"

    var type: ActionCellType

    init(type: ActionCellType) {
        self.type = type
    }

    var title: String {
        get {
            switch type {
            case .leaveKeySyncGroup:
                return NSLocalizedString("Leave Device Group",
                                         comment: "Settings: Cell (button) title for leaving device group")
            }
        }
    }

    var titleColor: UIColor {
        get {
            switch type {
            case .leaveKeySyncGroup:
                return .AppleBlue
            }
        }
    }
}

