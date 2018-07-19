//
//  AutoWizardStepsViewController.swift
//  pEp
//
//  Created by Hussein on 22/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class AutoWizardStepsViewController: BaseViewController {
    
    var viewModel: AutoWizardStepsViewModel?
    static let storyBoardID = "AutoWizardStepsKeyImport"
    
    @IBOutlet weak var action: UIButton!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var stepDescription: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if let vm = viewModel {
            vm.delegate = self
        }
    }

    // MARK: - Actions

    //TODO: Use just one IBAction, as start and cancel are complementary
    //TODO: Use viewModel.

    @IBAction func onStartClicked(_ sender: Any) {
        if let vm = viewModel {
            updateState()
            vm.start() 
        }

        //hideStartButton()
        action.isHidden = true
        //showCancelButton()
        cancel.isHidden = false
        //showCurrentStep()
        stepDescription.isHidden = false
        loading.isHidden = false
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        action.isHidden = false
        cancel.isHidden = true
        stepDescription.isHidden = true
        loading.isHidden = true
        //hideStartButton()
        //showCancelButton()
        //showCurrentStep()
    }

    private func updateState() {
        if let vm = viewModel {
            action.titleLabel?.text = vm.userAction
            stepDescription.text = vm.stepDescription
            loading.isHidden = vm.isWaiting
        }
    }
}

extension AutoWizardStepsViewController: AutoWizardViewControllerDelegate {
    func showError(error: Error) {

    }

    func notifyUpdate() {
        updateState()
    }


}
public protocol AutoWizardViewControllerDelegate: class {
    func showError(error: Error)
    func notifyUpdate()
}
