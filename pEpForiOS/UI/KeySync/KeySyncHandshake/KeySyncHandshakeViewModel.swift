//
//  KeySyncHandshakeViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PlanckToolbox

protocol KeySyncHandshakeViewModelDelegate: AnyObject {
    func showPicker(withLanguages languages: [String], selectedLanguageIndex: Int?)
    func closePicker()
    func change(handshakeWordsTo: String)
    func change(myFingerprints: String, partnerFingerprints: String)
}

final class KeySyncHandshakeViewModel {
    enum Action {
        case cancel, decline, accept, changeLanguage, lenght
    }

    private struct Localized {
        struct Message {
            static let twoDevices = NSLocalizedString("Please make sure you have both devices together so you can compare the Trustwords on both devices. Are the Trustwords below equal to the Trustwords on the other device?",
                                                      comment: "keySync handshake alert message for two devices in group")
            static let moreThanTwoDevices = NSLocalizedString("Please make sure you have the devices together so you can compare the Trustwords on the devices. Are the Trustwords below equal to the Trustwords on the other device?",
                                                              comment: "keySync handshake alert message for more than two devices in group")
        }
    }

    let trustManagementUtil = TrustManagementUtil()

    var completionHandler: ((KeySyncHandshakeViewController.Action) -> Void)? //!!!: A viewModel must not know the Controller

    weak var delegate: KeySyncHandshakeViewModelDelegate?
    var fullTrustWords = false //Internal since testing
    private var languageCode: String = Locale.current.languageCode == "de" ? "de" : "en"

    /// The email address of the account this is doing the key sync
    private var email: String?

    /// The name of the (local) user doing the key sync
    private var username: String?

    private var meFPR: String?
    private var partnerFPR: String?
    private var isNewGroup = true

    private var _languages = [TrustwordsLanguage]()

    func languages(completion: @escaping ([TrustwordsLanguage]) -> ()) {
        if !_languages.isEmpty {
            completion(_languages)
        } else {
            TrustwordsLanguage.languages() { [weak self] langs in
                guard let me = self else {
                    // UI, this can happen
                    return
                }

                if langs.isEmpty {
                    Log.shared.errorAndCrash("There must be trustwords languages defined")
                }

                let acceptedLanguages = AppSettings.shared.acceptedLanguagesCodes
                if acceptedLanguages.isEmpty {
                    me._languages = langs
                    completion(langs)
                } else {
                    let filteredLangs = langs.filter({acceptedLanguages.contains($0.code)})
                    me._languages = filteredLangs
                    completion(filteredLangs)
                }
            }
        }
    }

    func didSelect(languageRow: Int) {
        languages { [weak self] langs in
            DispatchQueue.main.async {
                guard let me = self else {
                    // UI, this can happen
                    return
                }
                me.languageCode = langs[languageRow].code
                me.delegate?.closePicker()
                me.updateTrustwords()
            }
        }
    }

    func handle(action: Action) {
        switch action {
        case .accept, .cancel, .decline:
            guard let action = viewControllerAction(viewModelAction: action) else {
                return
            }
            completionHandler?(action)
        case .changeLanguage:
            handleChangeLanguageButton()
        case .lenght:
            handleChangeLengthButton()
        }
    }

    func setKeySyncHandshakeData(keySyncHandshakeData: KeySyncHandshakeData) {
        self.email = keySyncHandshakeData.email
        self.meFPR = keySyncHandshakeData.fingerprintLocal
        self.partnerFPR = keySyncHandshakeData.fingerprintOther
        self.isNewGroup = keySyncHandshakeData.isNewGroup

        updateTrustwords()
    }

    func getMessage() -> String {
        return isNewGroup
        ? Localized.Message.twoDevices
        : Localized.Message.moreThanTwoDevices
    }

    func updateTrustwords() {
        trustWords { [weak self] (trustWords) in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.delegate?.change(handshakeWordsTo: trustWords)
        }
    }
}

// MARK: - Private

extension KeySyncHandshakeViewModel {
    private func setFingerprints() {
        guard let meFPR = meFPR, let partnerFPR = partnerFPR else {
            Log.shared.errorAndCrash("Nil meFingerPrints or Nil partnerFingerPrints")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let delegate = me.delegate else {
                Log.shared.errorAndCrash("Lost delegate")
                return
            }
            delegate.change(myFingerprints: meFPR, partnerFingerprints: partnerFPR)
        }
    }

    private func trustWords(completion: @escaping (String) -> Void) {
        guard let meFPR = meFPR, let partnerFPR = partnerFPR else {
            Log.shared.errorAndCrash("Nil meFingerPrints or Nil partnerFingerPrints")
            completion("")
            return
        }

        guard let theEmail = email else {
            Log.shared.errorAndCrash("Need a valid email for getting key sync trustwords")
            return
        }

        setFingerprints()

        trustManagementUtil.getTrustwords(email: theEmail,
                                          username: username,
                                          fpr1: meFPR,
                                          fpr2: partnerFPR,
                                          language: languageCode,
                                          full: fullTrustWords) { (trustwords) in
            DispatchQueue.main.async {
                completion(trustwords ?? "")
            }
        }
    }

    public func handleChangeLengthButton() {
        fullTrustWords.toggle()
        updateTrustwords()
    }

    private func handleChangeLanguageButton() {
        languages { [weak self] langs in
            DispatchQueue.main.async {
                guard let me = self else {
                    // UI, this can happen
                    return
                }
                guard !langs.isEmpty else {
                    Log.shared.errorAndCrash("Wont show picker, no languages to show")
                    return
                }
                let languagesNames = langs.map { $0.name.capitalized(with: Locale.current) }
                let selectedlanguageIndex = langs.map { $0.code }.firstIndex(of: me.languageCode)

                me.delegate?.showPicker(withLanguages: languagesNames,
                                        selectedLanguageIndex: selectedlanguageIndex)
            }
        }
    }

    private func viewControllerAction(viewModelAction: KeySyncHandshakeViewModel.Action)
        -> KeySyncHandshakeViewController.Action? {
            switch viewModelAction {
            case .accept:
                return .accept
            case .cancel:
                return .cancel
            case .decline:
                return .decline
            case .changeLanguage:
                return nil
            case .lenght:
                return nil
            }
    }
}
