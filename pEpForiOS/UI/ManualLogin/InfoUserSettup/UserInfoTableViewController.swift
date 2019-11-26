//
//  UserInfoTableViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit
import pEpIOSToolbox
import MessageModel

class UserInfoTableViewController: BaseViewController, TextfieldResponder, UITextFieldDelegate {
    @IBOutlet weak var manualAccountSetupContainerView: ManualAccountSetupContainerView!

    var fields = [UITextField]()
    var responder = 0
    var accounts = [Account]()

    //TODO: ALE rename
    public var model: VerifiableAccountProtocol?

    public override func viewDidLoad() {
        super.viewDidLoad()

        let accountSetupView = manualAccountSetupContainerView.manualAccountSetupView
        accountSetupView?.delegate = self
        accountSetupView?.textFieldsDelegate = self
        fields = manualSetupViewTextFeilds()

        accountSetupView?.titleLabel.text = NSLocalizedString("Account", comment: "Title for manual account setup")
        let nextButtonTittle = NSLocalizedString("Next", comment: "Next button title for manual account setup")
        accountSetupView?.nextButton.setTitle(nextButtonTittle, for: .normal)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateViewFromInitialModel()
        updateView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder(!viewModelOrCrash().isValidName)
    }

    /**
     Puts the model into the view, in case it was set by the invoking view controller.
     */
    func updateViewFromInitialModel() {
        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return
        }
        setupView.firstTextField.text = viewModelOrCrash().userName
        setupView.secondTextField.text = viewModelOrCrash().address
        setupView.thirdTextField.text = viewModelOrCrash().password
    }

    func updateView() {
        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return
        }
        setupView.nextButton.isEnabled = viewModelOrCrash().isValidUser
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextResponder(textField)

        if viewModelOrCrash().isValidUser {
            performSegue(withIdentifier: .IMAPSettings , sender: self)
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        changedResponder(textField)
    }

    @IBAction func didTapOnView(_ sender: Any) {
        view.endEditing(true)
    }
}

// MARK: - ManualAccountSetupViewDelegate

extension UserInfoTableViewController: ManualAccountSetupViewDelegate {
    func didChangeFirst(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.userName = textField.text
        model = vm
        updateView()
    }

    func didChangeSecond(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.address = textField.text
        model = vm
        updateView()
    }

    func didChangeThierd(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.password = textField.text
        model = vm
        updateView()
    }

    func didChangeFourth(_ textField: UITextField) {
        var vm = viewModelOrCrash()
        vm.loginName = textField.text
        model = vm
        updateView()
    }

    func didPressCancelButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func didPressNextButton() {
        guard viewModelOrCrash().isValidUser else {
            Log.shared.errorAndCrash("Next button enable with not ValidUser in ManualAccountSetupView")
            return
        }
        performSegue(withIdentifier: .IMAPSettings , sender: self)
    }


}

// MARK: - Helpers

extension UserInfoTableViewController {
    func viewModelOrCrash() -> VerifiableAccountProtocol {
        if let vm = model {
            return vm
        } else {
            Log.shared.errorAndCrash("No view model")
            let vm = BaseVerifiableAccount()
            model = vm
            return vm
        }
    }
}

// MARK: - Navigation

extension UserInfoTableViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case IMAPSettings
        case noSegue
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .IMAPSettings:
            if let destination = segue.destination as? IMAPSettingsTableViewController {
                destination.appConfig = appConfig
                destination.model = model
            }
            break
        default:
            break
        }
    }
}

// MARK: - Private

extension UserInfoTableViewController {
    private func manualSetupViewTextFeilds() -> [UITextField] {
        guard let setupView = manualAccountSetupContainerView.manualAccountSetupView else {
            Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
            return []
        }
        return [setupView.firstTextField,
                setupView.secondTextField,
                setupView.thirdTextField,
                setupView.fourthTextField]
    }
}
