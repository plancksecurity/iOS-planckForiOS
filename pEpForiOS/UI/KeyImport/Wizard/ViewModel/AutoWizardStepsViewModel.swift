//
//  AutoWizardStepsViewModel.swift
//  pEp
//
//  Created by Hussein on 03/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public protocol AutoWizardStepsViewModelDelegate: class {
    func showError(error: Error)
    func notifyUpdate()
}

class AutoWizardStepsViewModel {
    private let keyImportService: KeyImportServiceProtocol
    let account: Account
    private var keyImportWizzard: KeyImportWizzard
    var userAction: String
    var stepDescription: String
    var isWaiting: Bool
    var isHiddingDescription: Bool {
        get {
            return stepDescription.isEmpty
        }
    }
    var isHiddingAction: Bool {
        get {
            return userAction.isEmpty
        }
    }

    weak var delegate: AutoWizardStepsViewModelDelegate?
    
    init(keyImportService: KeyImportServiceProtocol, account: Account,
         keyImportWizzard: KeyImportWizzard) {
        self.keyImportService = keyImportService
        self.account = account

            self.userAction = keyImportWizzard.userAction
            self.stepDescription = keyImportWizzard.stepDescription
            self.isWaiting = keyImportWizzard.isWaiting
            keyImportWizzard.account = account


        if (!keyImportWizzard.starter) {
            keyImportWizzard.next()
        }
        /*else {
            let wizard = KeyImportWizzard(keyImportService: keyImportService, starter: true)
            self.userAction = wizard.userAction
            self.stepDescription = wizard.stepDescription
            self.isWaiting = wizard.isWaiting
            self.keyImportWizzard = wizard
        }*/

        self.keyImportWizzard = keyImportWizzard
        keyImportWizzard.delegate = self
        self.notifyUpdate() //IOS-1028: should not be neccessarry
    }

    func start() {
        keyImportWizzard.start()
    }

    func next() {
        keyImportWizzard.next()
    }

    func finish() {
        keyImportWizzard.finish()
    }

    func cancel() {
        fatalError("Unimplemented stub")
        //TODO code when cancel is pressed.
    }
}

extension AutoWizardStepsViewModel: KeyImportWizardDelegate {
    func showError(error: Error) {
        fatalError("Not implemented yet")
    }
    func notifyUpdate() {
        userAction = keyImportWizzard.userAction
        stepDescription = keyImportWizzard.stepDescription
        isWaiting = keyImportWizzard.isWaiting
        keyImportWizzard.account = account
    }
}
