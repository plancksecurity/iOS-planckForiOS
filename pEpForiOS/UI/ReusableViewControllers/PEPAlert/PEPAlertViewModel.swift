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
    var delegate: PEPAlertViewModelDelegate? { get set }

    func add(action: PEPUIAlertAction)
    func handleButtonEvent(tag: Int)
}

protocol PEPAlertViewModelDelegate: class {
    func dissmiss()
}

final class PEPAlertViewModel {

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

    func add(action: PEPUIAlertAction) {
        alertActions.append(action)
    }

    func handleButtonEvent(tag: Int) {
        alertActions[tag].execute()
    }
}
