//
//  ComposeWithAutocompleteViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class ComposeViewControllerModel {
    var shortMessage: String? = nil
    var to: String? = nil
}

class ComposeWithAutocompleteViewController: UITableViewController, UITextFieldDelegate {

    var appConfig: AppConfig?
    var model = ComposeViewControllerModel.init()

    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var ccTextField: UITextField!
    @IBOutlet weak var bccTextField: UITextField!
    @IBOutlet weak var shortMessageTextField: UITextField!
    @IBOutlet weak var longMessageTextField: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true 
    }

    func updateView() {
        if let subject = model.shortMessage {
            shortMessageTextField.text = subject
        }
        if let to = model.to {
            toTextField.text = to
        }
    }
}