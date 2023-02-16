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

    @IBOutlet private weak var myFingerprintsLabel: UILabel! {
        didSet {
            myFingerprintsLabel.setPEPFont(style: .callout, weight: .regular)
            myFingerprintsLabel.backgroundColor = .clear
            myFingerprintsLabel.textColor = .label
        }
    }

    @IBOutlet private weak var myFingerprintsValueLabel: UILabel! {
        didSet {
            myFingerprintsLabel.setPEPFont(style: .caption1, weight: .regular)
            myFingerprintsLabel.backgroundColor = .clear
            myFingerprintsLabel.textColor = .label
        }
    }

    @IBOutlet private weak var otherDeviceFingerprintsLabel: UILabel! {
        didSet {
            otherDeviceFingerprintsLabel.setPEPFont(style: .callout, weight: .regular)
            otherDeviceFingerprintsLabel.backgroundColor = .clear
            otherDeviceFingerprintsLabel.textColor = .label
        }
    }

    @IBOutlet private weak var otherDeviceFingerprintsValueLabel: UILabel! {
        didSet {
            otherDeviceFingerprintsValueLabel.setPEPFont(style: .caption1, weight: .regular)
            otherDeviceFingerprintsValueLabel.backgroundColor = .clear
            otherDeviceFingerprintsValueLabel.textColor = .label
        }
    }
    
    @IBOutlet private weak var trustwordsView: UIView! {
        didSet {
            trustwordsView.backgroundColor = .systemBackground
            trustwordsView.layer.borderColor = UIColor.pEpGreyLines.cgColor
            trustwordsView.layer.cornerRadius = 3
            trustwordsView.layer.borderWidth = 1
        }
    }

    @IBOutlet private weak var trustwordsLabel: UILabel! {
        didSet {
            trustwordsLabel.setPEPFont(style: .body, weight: .regular)
            trustwordsLabel.backgroundColor = .clear
            trustwordsLabel.textColor = .label
        }
    }

    @IBOutlet private weak var contentView: KeyInputView! {
        didSet {
            contentView.backgroundColor = .systemGray6
            let languangePicker = UIPickerView()
            languangePicker.dataSource = self
            languangePicker.delegate = self
            contentView.inputView = languangePicker
        }
    }

    @IBOutlet private weak var alertTitle: UILabel! {
        didSet {
            let titleText = NSLocalizedString("p≡p Sync", comment: "keySync handshake alert title")
            alertTitle.font = UIFont.pepFont(style: .body, weight: .semibold)
            alertTitle.attributedText = titleText.paintPEPToPEPColour()
        }
    }

    @IBOutlet private weak var message: UILabel! {
        didSet {
            message.font = UIFont.pepFont(style: .footnote, weight: .regular)
            message.text = viewModel.getMessage()
        }
    }

    @IBOutlet private weak var accept: UIButton! {
        didSet {
            setFont(button: accept)
            accept.setTitleColor(.pEpGreen, for: .normal)
            accept.setTitle(NSLocalizedString("Confirm",
                                              comment: "accept hand shake confirm button"), for: .normal)
            accept.backgroundColor = .systemGray6
        }
    }

    @IBOutlet private weak var decline: UIButton! {
        didSet {
            setFont(button: decline)
            decline.setTitleColor(.pEpRed, for: .normal)
            decline.setTitle(NSLocalizedString("Reject",
                                               comment: "reject hand shake button"), for: .normal)
            decline.backgroundColor = .systemGray6
        }
    }

    @IBOutlet private weak var cancel: UIButton! {
        didSet {
            setFont(button: cancel)
            cancel.setTitleColor(.pEpGreyText, for: .normal)
            cancel.setTitle(NSLocalizedString("Not Now",
                                              comment: "not now button"), for: .normal)
            cancel.backgroundColor = .systemGray6
        }
    }

    @IBOutlet private weak var buttonsView: UIView! {
        didSet {
            buttonsView.backgroundColor = UIColor.separator
        }
    }

    private let viewModel = KeySyncHandshakeViewModel()
    private var pickerLanguages = [String]()
    private var meFPR: String?
    private var partnerFPR: String?
    private var isNewGroup = true

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.setFingerPrints(meFPR: meFPR,
                                  partnerFPR: partnerFPR,
                                  isNewGroup: isNewGroup)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        message.text = viewModel.getMessage()
    }

    func setFingerPrints(meFPR: String,
                         partnerFPR: String,
                         isNewGroup: Bool) {
        self.meFPR = meFPR
        self.partnerFPR = partnerFPR
        self.isNewGroup = isNewGroup
    }

    private func setFont(button: UIButton) {
        button.titleLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
    }

    @IBAction private func didPress(_ sender: UIButton) {
        guard let action = pressedAction(tag: sender.tag) else {
            return
        }
        viewModel.handle(action: action)
    }

    @IBAction private func didLongPressWords(_ sender: UILongPressGestureRecognizer) {
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

    func showPicker(withLanguages languages: [String], selectedLanguageIndex: Int?) {
        pickerLanguages = languages
        DispatchQueue.main.async { [weak self] in
            if let row = selectedLanguageIndex,
                let picker = self?.contentView.inputView as? UIPickerView {
                picker.selectRow(row, inComponent: 0, animated: true)
            }
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
            self?.trustwordsLabel.text = handshakeWordsTo
        }
    }

    func change(myFingerprints: String, partnerFingerprints: String) {
        myFingerprintsValueLabel.text = myFingerprints
        otherDeviceFingerprintsValueLabel.text = partnerFingerprints
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
