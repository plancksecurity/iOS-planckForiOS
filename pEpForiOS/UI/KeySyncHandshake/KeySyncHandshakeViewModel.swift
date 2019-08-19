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
    func dissmissView()
    func showPicker(withLanguages languages: [String])
    func closePicker()
    func change(handshakeWordsTo: String)
}

final class KeySyncHandshakeViewModel {
    enum Action {
        case cancel, decline, accept, changeLanguage
    }

    var completionHandler: ((KeySyncHandshakeViewController.Action) -> Void)?

    weak var delegate: KeySyncHandshakeViewModelDelegate?
    var fullTrustWords = false //Internal since testing
    private var languageCode = Locale.current.languageCode
    private var meFPR: String?
    private var partnerFPR: String?
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
            delegate?.dissmissView()
        case .changeLanguage:
            handleChangeLanguageButton()
        }
    }

    func fingerPrints(meFPR: String?, partnerFPR: String?) {
        self.meFPR = meFPR
        self.partnerFPR = partnerFPR
        delegate?.change(handshakeWordsTo: trustWords())
    }

    func didLongPressWords() {
        fullTrustWords = !fullTrustWords
        delegate?.change(handshakeWordsTo: trustWords())
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
        delegate?.showPicker(withLanguages: languagesNames)
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
