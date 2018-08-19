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
            updateState()
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
        loading.stopAnimating()


    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        self.viewModel?.cancel()
        self.navigationController?.popViewController(animated: true)
    }

    private func updateState() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No vm")
            return
        }
        action.titleLabel?.text = vm.userAction
        stepDescription.text = vm.stepDescription
        stepDescription.isHidden = vm.isHiddingDescription
        vm.isWaiting ? loading.stopAnimating() : loading.startAnimating() //IOS-1028 I think this is the wrong way around, I did not want to change the implementation though
    }
}

extension AutoWizardStepsViewController: AutoWizardStepsViewModelDelegate {
    func showError(error: Error) {
        fatalError("Unimplemented stub")
    }

    func notifyUpdate() {
        updateState()
    }
}
