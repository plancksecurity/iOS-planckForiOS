//
//  ViewController.swift
//  MacCatalystEvaluation
//
//  Created by Andreas Buff on 13.11.19.
//  Copyright © 2019 pEp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func showAlertPressed(_ sender: UIButton) {
        showAlert(style: .alert, showButtons: true)
    }

    @IBAction func showAlertWithoutButtonsPressed(_ sender: Any) {
        showAlert(style: .alert, showButtons: false)
    }

    @IBAction func showActionSheet(_ sender: Any) {
        showAlert(style: .actionSheet, showButtons: true)
    }

    // MARK: - PRIVATE

    private func showAlert(style: UIAlertController.Style, showButtons: Bool) {
        let message = "UIAlertController with\nstyle: \(style.rawValue == 0 ? ".actionSheet" : ".alert")\nNum Buttons to show: \(showButtons ? 2 : 0) +  Cancel\nexpected button (tint) colour: green\n\nSome longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah."

        let alertCtrl = UIAlertController(title: "Some Title",
                                          message: message,
                                          preferredStyle: style)
        if showButtons {
            alertCtrl.view.tintColor = UIColor.green
            alertCtrl.addAction(UIAlertAction(title: "OK",
                                              style: .default,
                                              handler: nil))
            alertCtrl.addAction(UIAlertAction(title: "2nd",
            style: .default,
            handler: nil))
            alertCtrl.addAction(UIAlertAction(title: "Cancel",
                                              style: .cancel,
                                              handler: nil))
        }
        if style == .actionSheet {
            alertCtrl.popoverPresentationController?.sourceView = view
        }

        present(alertCtrl, animated: true, completion: nil)
    }
}

