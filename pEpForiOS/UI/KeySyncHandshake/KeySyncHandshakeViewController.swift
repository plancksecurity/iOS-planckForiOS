//
//  KeySyncHandshakeViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class KeySyncHandshakeViewController: UIViewController {
    static let storyboardId = "KeySyncHandshakeViewController"
    
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var keySyncWorlds: UITextView! {
        didSet {
            let languangePicker = UIPickerView()
            languangePicker.dataSource = self
            languangePicker.delegate = self
            keySyncWorlds.inputView = languangePicker
        }
    }

    enum Action {
        case cancel, decline, accept
    }

    var completion: ((Action) -> Void)?

    private let viewModel = KeySyncHandshakeViewModel()
    private var pickerLanguages = [String]()
    private var meFPR: String?
    private var partnerFPR: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.fingerPrints(meFPR: meFPR, partnerFPR: partnerFPR)
    }

    func finderPrints(meFPR: String, partnerFPR: String) {
        self.meFPR = meFPR
        self.partnerFPR = partnerFPR
    }

    @IBAction func didPress(_ sender: UIButton) {
        guard let action = pressedAction(tag: sender.tag) else {
            return
        }
        viewModel.didPress(action: action)
    }
}

// MARK: - KeySyncHandshakeViewModelDelegate
extension KeySyncHandshakeViewController: KeySyncHandshakeViewModelDelegate {
    func didPress(action: KeySyncHandshakeViewModel.Action) {
        guard let action = viewControllerAction(viewModelAction: action) else {
            return
        }
        completion?(action)
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    func showPicker(withLanguages languages: [String]) {
        pickerLanguages = languages
        DispatchQueue.main.async { [weak self] in
            self?.keySyncWorlds.becomeFirstResponder()
        }
    }

    func closePicker() {
        DispatchQueue.main.async { [weak self] in
            self?.keySyncWorlds.resignFirstResponder()
        }
    }

    func change(handshakeWordsTo: String) {
        DispatchQueue.main.async { [weak self] in
            self?.keySyncWorlds.text = handshakeWordsTo
        }
    }
}

// MARK: - UIPickerViewDelegate
extension KeySyncHandshakeViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerLanguages[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.didSelect(language: pickerLanguages[row])
    }
}

// MARK: - UIPickerViewDataSource
extension KeySyncHandshakeViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerLanguages.count
    }
}

// MARK: - Private
extension KeySyncHandshakeViewController {
    private func pressedAction(tag: Int) -> KeySyncHandshakeViewModel.Action? {
        switch tag {
        case 1:
            return .changeLanguage
        case 2:
            return .cancel
        case 3:
            return .decline
        case 4:
            return .accept
        default:
            return nil
        }
    }

    private func viewControllerAction(viewModelAction: KeySyncHandshakeViewModel.Action) -> Action? {
        switch viewModelAction {
        case .accept:
            return .accept
        case .cancel:
            return .cancel
        case .decline:
            return .decline
        case .changeLanguage:
            return nil
        }
    }
}
