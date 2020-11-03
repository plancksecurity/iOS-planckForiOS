//
//  PEPAlertViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol PEPAlertViewModelProtocol: class {
    var alertActionsCount: Int { get }
    var alertType: PEPAlertViewModel.AlertType { get }
    var delegate: PEPAlertViewModelDelegate? { get set }

    func add(action: PEPUIAlertAction)
    func handleButtonEvent(tag: Int)
}

protocol PEPAlertViewModelDelegate: class {
    func dismiss()
}

final class PEPAlertViewModel {

    enum AlertType {
        case pEpDefault
        case pEpSyncWizard
    }

    private let type: AlertType

    init() {
        self.type = .pEpDefault
    }

    init(alertType: AlertType) {
        self.type = alertType
    }

    var alertActions = [PEPUIAlertAction]()
    weak var _delegate: PEPAlertViewModelDelegate?
}


// MARK: - PEPAlertViewModelProtocol

extension PEPAlertViewModel: PEPAlertViewModelProtocol {
    var delegate: PEPAlertViewModelDelegate? {
        get { return _delegate }
        set { _delegate = newValue }
    }


    var alertActionsCount: Int {
        return alertActions.count
    }

    var alertType: PEPAlertViewModel.AlertType {
        return type
    }

    func add(action: PEPUIAlertAction) {
        alertActions.append(action)
    }

    func handleButtonEvent(tag: Int) {
        alertActions[tag].execute()
    }
}
