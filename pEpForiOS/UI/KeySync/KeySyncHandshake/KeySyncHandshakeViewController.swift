//
//  KeySyncHandshakeViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import PlanckToolbox
import MessageModel // Only for KeySyncHandshakeData

final class KeySyncHandshakeViewController: UIViewController {
    enum Action {
        case cancel, decline, accept
    }
    
    static let storyboardId = "KeySyncHandshakeViewController"
    
    @IBOutlet private weak var contentViewHeight: NSLayoutConstraint?

    @IBOutlet private weak var currentDeviceFingerprintsLabel: UILabel! {
        didSet {
            currentDeviceFingerprintsLabel.text = NSLocalizedString("This device:",
                                                                    comment: "Key Sync, fingerprint of this device - title")
        }
    }

    @IBOutlet private weak var currentDeviceFingerprintsValueLabel: UILabel?

    @IBOutlet private weak var otherDeviceFingerprintsLabel: UILabel! {
        didSet {
            otherDeviceFingerprintsLabel.text = NSLocalizedString("New device:",
                                                                  comment: "Key Sync, fingerprint of the other device - title")
        }
    }

    @IBOutlet private weak var otherDeviceFingerprintsValueLabel: UILabel?

    @IBOutlet private weak var trustwordsLabel: UILabel? {
        didSet {
            trustwordsLabel?.setPEPFont(style: .body, weight: .regular)
            trustwordsLabel?.backgroundColor = .clear
            trustwordsLabel?.textColor = .label
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

    private var defaultHeightValue: CGFloat? {
        didSet { defaultHeightValue = oldValue ?? defaultHeightValue }
    }

    private var defaultNumberOfLines: CGFloat? {
        didSet { defaultNumberOfLines = oldValue ?? defaultNumberOfLines }
    }

    @IBOutlet private weak var alertTitle: UILabel! {
        didSet {
            let titleText = NSLocalizedString("planck Sync", comment: "keySync handshake alert title")
            alertTitle.text = titleText
            alertTitle.font = UIFont.planckFont(style: .body, weight: .semibold)
        }
    }

    @IBOutlet private weak var message: UILabel! {
        didSet {
            message.font = UIFont.planckFont(style: .body, weight: .regular)
            message.text = viewModel.getMessage()
        }
    }

    @IBOutlet private weak var accept: UIButton! {
        didSet {
            setFont(button: accept)
            accept.setTitleColor(UIColor.pEpGreen, for: .normal)
            let confirmText = NSLocalizedString("Confirm", comment: "accept hand shake confirm button")
            accept.setTitle(confirmText, for: .normal)
            accept.backgroundColor = .systemGray6
            accept.isEnabled = true
        }
    }

    @IBOutlet private weak var decline: UIButton! {
        didSet {
            setFont(button: decline)
            decline.setTitleColor(.pEpRed, for: .normal)
            decline.setTitle(NSLocalizedString("Reject",
                                               comment: "reject hand shake button"), for: .normal)
            decline.backgroundColor = .systemGray6
            decline.isEnabled = true

        }
    }

    @IBOutlet private weak var cancel: UIButton! {
        didSet {
            setFont(button: cancel)
            cancel.setTitleColor(UIColor.primary(), for: .normal)
            cancel.setTitle(NSLocalizedString("Not Now", comment: "not now button"), for: .normal)
            cancel.backgroundColor = .systemGray6
            cancel.isEnabled = true
        }
    }

    @IBOutlet private weak var buttonsView: UIView! {
        didSet {
            buttonsView.backgroundColor = UIColor.separator
        }
    }
    @IBOutlet weak var fullTrustwordsButton: UIButton!
    
    private let viewModel = KeySyncHandshakeViewModel()
    private var pickerLanguages = [String]()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewModel.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Recalculate the trustwords, and update the UI.
        viewModel.updateTrustwords()
        hideKeyboardWhenTappedAround()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        message.text = viewModel.getMessage()
    }

    func setKeySyncHandshakeData(keySyncHandshakeData: KeySyncHandshakeData) {
        viewModel.setKeySyncHandshakeData(keySyncHandshakeData: keySyncHandshakeData)
    }

    private func setFont(button: UIButton) {
        button.titleLabel?.font = UIFont.planckFont(style: .body, weight: .regular)
    }

    @IBAction private func didPress(_ sender: UIButton) {
        guard let action = pressedAction(tag: sender.tag) else {
            return
        }
        if action == .length {
            rotate(button: sender)
        }
        viewModel.handle(action: action)
    }
    
    private func rotate(button: UIButton) {
        let fullTrustWords = viewModel.fullTrustWords
        UIView.animate(withDuration: 0.25, animations: {
            button.transform = fullTrustWords ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat.pi)
        })
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
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let me = self, let label = me.trustwordsLabel, let defaultHeight = me.contentViewHeight, defaultHeight.constant > 0 else {
                //May happen, the view didn't load yet.
                return
            }
            let lineHeight: Double = ceil(label.font.lineHeight)
            me.defaultHeightValue = defaultHeight.constant
            me.defaultNumberOfLines = round(label.frame.height / lineHeight)

            if me.viewModel.fullTrustWords {
                label.text = handshakeWordsTo
            } else {
                label.text = handshakeWordsTo.appending("...")
            }

            guard let defaultContentViewHeight = me.defaultHeightValue else {
                return
            }

            // Adapt the height of the content view if needed
            let numberOfLines = Double(label.calculateLines())

            guard let lines = me.defaultNumberOfLines else {
                return
            }

            if numberOfLines > lines {
                let heightToIncrease = (numberOfLines - lines) * lineHeight
                me.contentViewHeight?.constant = defaultContentViewHeight + heightToIncrease
            } else {
                me.contentViewHeight?.constant = defaultContentViewHeight
            }
        }
    }

    func change(myFingerprints: String, partnerFingerprints: String) {
        currentDeviceFingerprintsValueLabel?.text = myFingerprints.filter{!$0.isWhitespace}.prettyFingerPrint()
        otherDeviceFingerprintsValueLabel?.text = partnerFingerprints.filter{!$0.isWhitespace}.prettyFingerPrint()
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

// MARK: - Keyboard / Picker view

extension KeySyncHandshakeViewController {
    // Dismiss the picker view if needed.
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(KeySyncHandshakeViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
        case 5:
            return .length
        default:
            Log.shared.errorAndCrash("Tag not found")
            return nil
        }
    }
}
