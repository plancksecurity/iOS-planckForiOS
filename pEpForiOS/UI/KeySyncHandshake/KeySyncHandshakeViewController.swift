//
//  KeySyncHandshakeViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class KeySyncHandshakeViewController: UIViewController {
    enum Action {
        case cancel, decline, accept
    }

    static let storyboardId = "KeySyncHandshakeViewController"
    
    @IBOutlet weak var keySyncWords: UILabel! {
        didSet {
            keySyncWords.backgroundColor = .pEpLightBackground
            keySyncWords.layer.borderColor = UIColor.pEpGreyLines.cgColor
            keySyncWords.layer.cornerRadius = 3
            keySyncWords.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var contentView: KeyInputView! {
        didSet {
            contentView.backgroundColor = .pEpGreyBackground
            let languangePicker = UIPickerView()
            languangePicker.dataSource = self
            languangePicker.delegate = self
            contentView.inputView = languangePicker
        }
    }
    @IBOutlet weak var alertTitle: UILabel! {
        didSet {
            let alertTittle = NSLocalizedString("p≡p Sync", comment: "keySync handshake alert title")
            alertTitle.attributedText = alertTittle.paintPEPToPEPColour()
        }
    }
    @IBOutlet weak var message: UILabel! {
        didSet {
            message.text = NSLocalizedString("A second device is detected. \nPlease confirm the Trustwords on both devices to sync all your privacy. Shall we synchronize?", comment: "keySync handshake alert message")
        }
    }

    @IBOutlet weak var accept: UIButton! {
        didSet {
            accept.setTitleColor(.pEpGreen, for: .normal)
            accept.setTitle(NSLocalizedString("Sync", comment: "accept hand shake sync button"), for: .normal)
            accept.backgroundColor = .pEpGreyBackground
        }
    }
    @IBOutlet weak var decline: UIButton! {
        didSet {
            decline.setTitleColor(.pEpRed, for: .normal)
            decline.setTitle(NSLocalizedString("Decline", comment: "decline button"), for: .normal)
            decline.backgroundColor = .pEpGreyBackground
        }
    }
    @IBOutlet weak var cancel: UIButton! {
        didSet {
            cancel.setTitleColor(.pEpGreyText, for: .normal)
            cancel.setTitle(NSLocalizedString("Not Now", comment: "not now button"), for: .normal)
            cancel.backgroundColor = .pEpGreyBackground
        }
    }
    @IBOutlet weak var buttonsView: UIView! {
        didSet {
            buttonsView.backgroundColor = .pEpGreyButtonLines
        }
    }

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
        viewModel.handle(action: action)
    }

    @IBAction func didLongPressWords(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        viewModel.didLongPressWords()
    }

    func completionHandler(_ block: @escaping (Action) -> Void) {
        viewModel.completionHandler = block
    }
}

// MARK: - KeySyncHandshakeViewModelDelegate

extension KeySyncHandshakeViewController: KeySyncHandshakeViewModelDelegate {
    func dissmissView() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    func showPicker(withLanguages languages: [String]) {
        pickerLanguages = languages
        DispatchQueue.main.async { [weak self] in
            self?.contentView.becomeFirstResponder()
        }
    }

    func closePicker() {
        DispatchQueue.main.async { [weak self] in
            self?.contentView.resignFirstResponder()
        }
    }

    func change(handshakeWordsTo: String) {
        DispatchQueue.main.async { [weak self] in
            self?.keySyncWords.text = handshakeWordsTo
        }
    }
}

// MARK: - UIPickerViewDelegate
extension KeySyncHandshakeViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerLanguages[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.didSelect(languageRow: row)
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
}
