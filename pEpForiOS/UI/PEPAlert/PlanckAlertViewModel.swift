//
//  PlanckAlertViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol PlanckAlertViewModelProtocol: AnyObject {
    var alertActionsCount: Int { get }
    var alertType: PlanckAlertViewModel.AlertType { get }
    var delegate: PlanckAlertViewModelDelegate? { get set }

    func add(action: PlanckUIAlertAction)
    func handleButtonEvent(tag: Int)
}

protocol PlanckAlertViewModelDelegate: AnyObject {
    func dismiss()
}

final class PlanckAlertViewModel {

    enum AlertType {
        case planckDefault
        case planckSyncWizard
    }

    private let type: AlertType

    init() {
        self.type = .planckDefault
    }

    init(alertType: AlertType) {
        self.type = alertType
    }

    var alertActions = [PlanckUIAlertAction]()
    weak var _delegate: PlanckAlertViewModelDelegate?
}

// MARK: - PlanckAlertViewModelProtocol

extension PlanckAlertViewModel: PlanckAlertViewModelProtocol {
    var delegate: PlanckAlertViewModelDelegate? {
        get { return _delegate }
        set { _delegate = newValue }
    }

    var alertActionsCount: Int {
        return alertActions.count
    }

    var alertType: PlanckAlertViewModel.AlertType {
        return type
    }

    func add(action: PlanckUIAlertAction) {
        alertActions.append(action)
    }

    func handleButtonEvent(tag: Int) {
        alertActions[tag].execute()
    }
}
