//
//  KeySyncHandshakeViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework

protocol KeySyncHandshakeViewModelDelegate: class {
    func showPicker(withLanguages languages: [String], selectedLanguageIndex: Int?)
    func closePicker()
    func change(handshakeWordsTo: String)
}

final class KeySyncHandshakeViewModel {
    enum Action {
        case cancel, decline, accept, changeLanguage
    }

    private struct Localized {
        struct message {
            static let twoDevices = NSLocalizedString("Please make sure you have both devices together so you can compare the Trustwords on the devices. Are the Trustwords below equal to the Trustwords on both devices?",
                                               comment: "keySync handshake alert message for two devices in group")
            static let moreThanTwoDevices = NSLocalizedString("Please make sure you have the devices together so you can compare the Trustwords on the devices. Are the Trustwords below equal to the Trustwords on the other device?",
                                                       comment: "keySync handshake alert message for more than two devices in group")
        }
    }

    var completionHandler: ((KeySyncHandshakeViewController.Action) -> Void)? //!!!: A viewModel must not know the Controller

    weak var delegate: KeySyncHandshakeViewModelDelegate?
    var fullTrustWords = false //Internal since testing
    private var languageCode = Locale.current.languageCode
    private var meFPR: String?
    private var partnerFPR: String?
    private var isNewGroup = true
    private let pEpSession: PEPSessionProtocol
    private var _languages = [PEPLanguage]()
    private var languages: [PEPLanguage] {
        guard _languages.isEmpty else {
            return _languages
        }
        do {
            _languages = try pEpSession.languageList()
            return _languages
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            return []
        }
    }

    init(pEpSession: PEPSessionProtocol = PEPSession()) {
        self.pEpSession = pEpSession
    }

    func didSelect(languageRow: Int) {
        languageCode = languages[languageRow].code
        delegate?.closePicker()
        delegate?.change(handshakeWordsTo: trustWords())
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

    func fingerPrints(meFPR: String?, partnerFPR: String?, isNewGroup: Bool) {
        self.meFPR = meFPR
        self.partnerFPR = partnerFPR
        self.isNewGroup = isNewGroup
        delegate?.change(handshakeWordsTo: trustWords())
    }

    func didLongPressWords() {
        fullTrustWords = !fullTrustWords
        delegate?.change(handshakeWordsTo: trustWords())
    }

    func getMessage() -> String {
        return isNewGroup
            ? Localized.message.twoDevices
            : Localized.message.moreThanTwoDevices
    }
}

// MARK: - Private

extension KeySyncHandshakeViewModel {
    private func trustWords() -> String {
        guard let meFPR = meFPR, let partnerFPR = partnerFPR else {
            Log.shared.errorAndCrash("Nil meFingerPrints or Nil partnerFingerPrints")
            return String()
        }
        do {
            return try pEpSession.getTrustwordsFpr1(meFPR, fpr2: partnerFPR, language: languageCode,
                                                      full: fullTrustWords)
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            return ""
        }
    }

    private func handleChangeLanguageButton() {
        guard !languages.isEmpty else {
            Log.shared.errorAndCrash("Wont show picker, no languages to show")
            return
        }
        let languagesNames = languages.map { $0.name }
        let selectedlanguageIndex = languages.map { $0.code }.firstIndex(of: languageCode)

        delegate?.showPicker(withLanguages: languagesNames,
                             selectedLanguageIndex: selectedlanguageIndex)
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
