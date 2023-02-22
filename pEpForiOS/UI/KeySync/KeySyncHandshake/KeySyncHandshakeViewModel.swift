//
//  KeySyncHandshakeViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

protocol KeySyncHandshakeViewModelDelegate: AnyObject {
    func showPicker(withLanguages languages: [String], selectedLanguageIndex: Int?)
    func closePicker()
    func change(handshakeWordsTo: String)
    func change(myFingerprints: String, partnerFingerprints: String)
}

final class KeySyncHandshakeViewModel {
    enum Action {
        case cancel, decline, accept, changeLanguage
    }

    private struct Localized {
        struct Message {
            static let twoDevices = NSLocalizedString("Please make sure you have both devices together so you can compare the Trustwords on both devices. Are the Trustwords below equal to the Trustwords on the other device?",
                                               comment: "keySync handshake alert message for two devices in group")
            static let moreThanTwoDevices = NSLocalizedString("Please make sure you have the devices together so you can compare the Trustwords on the devices. Are the Trustwords below equal to the Trustwords on the other device?",
                                                       comment: "keySync handshake alert message for more than two devices in group")
        }
    }

    var completionHandler: ((KeySyncHandshakeViewController.Action) -> Void)? //!!!: A viewModel must not know the Controller

    weak var delegate: KeySyncHandshakeViewModelDelegate?
    var fullTrustWords = false //Internal since testing
    private var languageCode = Locale.current.languageCode ?? "en"
    private var identityMe: Identity?
    private var identityPartner: Identity?
    private var isNewGroup = true

    private var _languages = [TrustwordsLanguage]()

    // Prevent it from going out of scope when async methods are used on it.
    private let trustManagementUtil = TrustManagementUtil()

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
        }
    }

    func setIdentities(identityMe: Identity?,
                       identityPartner: Identity?,
                       isNewGroup: Bool) {
        self.identityMe = identityMe
        self.identityPartner = identityPartner
        self.isNewGroup = isNewGroup
        updateTrustwords()
    }

    func didLongPressWords() {
        fullTrustWords = !fullTrustWords
        updateTrustwords()
    }

    func getMessage() -> String {
        return isNewGroup
            ? Localized.Message.twoDevices
            : Localized.Message.moreThanTwoDevices
    }
}

// MARK: - Private

extension KeySyncHandshakeViewModel {

    private func updateTrustwords() {
        trustWords { [weak self] (trustWords) in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.delegate?.change(handshakeWordsTo: trustWords)
        }
    }

    private func setFingerprints(identityOwn: Identity, identityPartner: Identity) {
        trustManagementUtil.getFingerprints(identityOwn: identityOwn, identityPartner: identityPartner) {
            [weak self] fingerprintOwn, fingerprintPartner in
            guard let theFingerprintOwn = fingerprintOwn else {
                Log.shared.errorAndCrash(message: "No own fingerprint")
                return
            }

            guard let theFingerprintPartner = fingerprintPartner else {
                Log.shared.errorAndCrash(message: "No partner fingerprint")
                return
            }

            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard let delegate = me.delegate else {
                Log.shared.errorAndCrash("Lost delegate")
                return
            }

            delegate.change(myFingerprints: theFingerprintOwn,
                            partnerFingerprints: theFingerprintPartner)
        }
    }

    private func trustWords(completion: @escaping (String) -> Void) {
        guard let identityMe = identityMe, let identityPartner = identityPartner else {
            Log.shared.errorAndCrash("Identities are nil (own or partner)")
            completion("")
            return
        }
        setFingerprints(identityOwn: identityMe, identityPartner: identityPartner)
        trustManagementUtil.getTrustwords(for: identityMe, and: identityPartner, language: languageCode, long: fullTrustWords) {  (trustwords) in
            DispatchQueue.main.async {
                completion(trustwords ?? "")
            }
        }
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
            }
    }
}
