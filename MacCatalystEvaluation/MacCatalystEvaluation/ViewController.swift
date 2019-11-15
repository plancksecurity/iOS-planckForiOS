//
//  ViewController.swift
//  MacCatalystEvaluation
//
//  Created by Andreas Buff on 13.11.19.
//  Copyright © 2019 pEp. All rights reserved.
//

import UIKit
#if targetEnvironment(macCatalyst)
import XPC
#endif

class ViewController: UIViewController {

     public private(set) var imagePicker = UIImagePickerController()

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

    @IBAction func showActionSheet(_ sender: UIButton) {
        showAlert(style: .actionSheet, showButtons: true, anchor: sender)
    }
    @IBAction func writeAndReadKeychainPressed(_ sender: UIButton) {
        let key = UUID().uuidString
        let password = UUID().uuidString
        //write
        let success = KeyChain.add(key: key, password: password)
        guard success else {
            showAlert(title: "Fail",
                      message: "Failed to save somthing to KeyChain",
                      style: .alert,
                      showButtons: true)
            return
        }
        //read
        let pass = KeyChain.password(key: key)
        if pass != password {
            showAlert(title: "Fail",
                      message: "Failed to read from KeyChain",
                      style: .alert,
                      showButtons: true)
            return
        }
        // Success
        showAlert(title: "Success",
                  message: "Successfully wrote and read to / from the Key Chain",
                  style: .alert,
                  showButtons: true)
    }

    @IBAction func showMediaPicker(_ sender: UIButton) {
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true) { [weak self] in
            self?.showAlert(title: "ImagePicker",
                            message: "didFinishPickingMediaWithInfo with: \(info.debugDescription)",
                style: .alert,
                showButtons: true)
        }
    }
}

// MARK: - PRIVATE

extension ViewController {

    private func showAlert(title: String? = nil,
                           message: String? = nil,
                           style: UIAlertController.Style,
                           showButtons: Bool,
                           anchor: UIView? = nil) {
        let message = message ?? "UIAlertController with\nstyle: \(style.rawValue == 0 ? ".actionSheet" : ".alert")\nNum Buttons to show: \(showButtons ? 2 : 0) +  Cancel\nexpected button (tint) colour: green\n\nSome longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah Some longer message blah blah."
        let title = title ?? "Some Title"

          let alertCtrl = UIAlertController(title: title,
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
              alertCtrl.popoverPresentationController?.sourceView = anchor ?? view
              alertCtrl.popoverPresentationController?.permittedArrowDirections = .left
          }

          present(alertCtrl, animated: true, completion: nil)
      }
}

