//
//  AutoWizardStepsViewModel.swift
//  pEp
//
//  Created by Hussein on 03/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


class AutoWizardStepsViewModel {
    private let keyImportService: KeyImportServiceProtocol
    let account: Account
    private var keyImportWizzard: KeyImportWizzard?
    var userAction: String
    var stepDescription: String
    var isWaiting: Bool
    var delegate: AutoWizardViewControllerDelegate?
    
    init(keyImportService: KeyImportServiceProtocol, account: Account,
         keyImportWizzard: KeyImportWizzard? = nil) {
        self.keyImportService = keyImportService
        self.account = account

        if let wizard = keyImportWizzard {
            self.userAction = wizard.userAction
            self.stepDescription = wizard.stepDescription
            self.isWaiting = wizard.isWaiting
            wizard.account = account
            wizard.delegate = self
            self.keyImportWizzard = wizard

        } else {
            self.userAction = "No user action"
            self.stepDescription = "No description"
            self.isWaiting = false
        }
        /*else {
            let wizard = KeyImportWizzard(keyImportService: keyImportService, starter: true)
            self.userAction = wizard.userAction
            self.stepDescription = wizard.stepDescription
            self.isWaiting = wizard.isWaiting
            self.keyImportWizzard = wizard
        }*/


    }

    func start() {
        keyImportWizzard?.start()
    }

    func next() {
        keyImportWizzard?.next()
    }

    func finish() {
        keyImportWizzard?.finish()
    }
}

extension AutoWizardStepsViewModel: KeyImportWizardDelegate {
    func showError(error: Error) {
        fatalError("Not implemented yet")
    }
    func notifyUpdate() {

    }
}
